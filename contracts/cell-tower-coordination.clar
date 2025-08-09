;; Cell Tower Site Coordination Contract
;; Manages permits and inspections for cellular communication towers

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-TOWER-NOT-FOUND (err u301))
(define-constant ERR-INVALID-HEIGHT (err u302))
(define-constant ERR-PERMIT-ALREADY-EXISTS (err u303))
(define-constant ERR-INVALID-COORDINATES (err u304))

;; Data Variables
(define-data-var next-tower-id uint u1)
(define-data-var total-towers uint u0)
(define-data-var max-tower-height uint u500) ;; 500 feet max

;; Data Maps
(define-map cell-towers
  { tower-id: uint }
  {
    location: (string-ascii 100),
    latitude: int,
    longitude: int,
    height: uint,
    tower-type: (string-ascii 30),
    owner: principal,
    status: (string-ascii 20),
    permit-date: uint,
    last-inspection: uint,
    next-inspection: uint
  }
)

(define-map tower-permits
  { tower-id: uint }
  {
    permit-number: (string-ascii 50),
    issued-date: uint,
    expiry-date: uint,
    permit-type: (string-ascii 30),
    approved-by: principal,
    conditions: (string-ascii 200)
  }
)

(define-map inspection-records
  { tower-id: uint, inspection-id: uint }
  {
    inspection-date: uint,
    inspector: principal,
    inspection-type: (string-ascii 30),
    result: (string-ascii 20),
    violations: (string-ascii 200),
    next-action-required: bool
  }
)

(define-map authorized-inspectors
  { inspector: principal }
  { authorized: bool, certification-type: (string-ascii 50) }
)

(define-map tower-operators
  { operator: principal }
  { authorized: bool, company-name: (string-ascii 100) }
)

;; Authorization Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (is-authorized-inspector)
  (default-to false (get authorized (map-get? authorized-inspectors { inspector: tx-sender })))
)

(define-private (is-authorized-operator)
  (default-to false (get authorized (map-get? tower-operators { operator: tx-sender })))
)

;; Administrative Functions
(define-public (add-inspector (inspector principal) (certification-type (string-ascii 50)))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-inspectors
      { inspector: inspector }
      { authorized: true, certification-type: certification-type }
    ))
  )
)

(define-public (add-tower-operator (operator principal) (company-name (string-ascii 100)))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (ok (map-set tower-operators
      { operator: operator }
      { authorized: true, company-name: company-name }
    ))
  )
)

(define-public (set-max-tower-height (new-height uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (ok (var-set max-tower-height new-height))
  )
)

;; Core Functions
(define-public (apply-for-tower-permit
  (location (string-ascii 100))
  (latitude int)
  (longitude int)
  (height uint)
  (tower-type (string-ascii 30))
  (permit-number (string-ascii 50))
)
  (let
    (
      (tower-id (var-get next-tower-id))
    )
    (asserts! (is-authorized-operator) ERR-NOT-AUTHORIZED)
    (asserts! (> (len location) u0) ERR-INVALID-COORDINATES)
    (asserts! (<= height (var-get max-tower-height)) ERR-INVALID-HEIGHT)
    (asserts! (> height u0) ERR-INVALID-HEIGHT)

    ;; Create tower record
    (map-set cell-towers
      { tower-id: tower-id }
      {
        location: location,
        latitude: latitude,
        longitude: longitude,
        height: height,
        tower-type: tower-type,
        owner: tx-sender,
        status: "pending-approval",
        permit-date: u0,
        last-inspection: u0,
        next-inspection: u0
      }
    )

    ;; Create permit application
    (map-set tower-permits
      { tower-id: tower-id }
      {
        permit-number: permit-number,
        issued-date: u0,
        expiry-date: u0,
        permit-type: "construction",
        approved-by: CONTRACT-OWNER,
        conditions: ""
      }
    )

    (var-set next-tower-id (+ tower-id u1))
    (ok tower-id)
  )
)

(define-public (approve-tower-permit
  (tower-id uint)
  (conditions (string-ascii 200))
)
  (let
    (
      (tower (unwrap! (map-get? cell-towers { tower-id: tower-id }) ERR-TOWER-NOT-FOUND))
      (permit (unwrap! (map-get? tower-permits { tower-id: tower-id }) ERR-TOWER-NOT-FOUND))
    )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)

    ;; Update tower status
    (map-set cell-towers
      { tower-id: tower-id }
      (merge tower {
        status: "approved",
        permit-date: block-height,
        next-inspection: (+ block-height u17280) ;; ~120 days
      })
    )

    ;; Update permit
    (ok (map-set tower-permits
      { tower-id: tower-id }
      (merge permit {
        issued-date: block-height,
        expiry-date: (+ block-height u525600), ;; ~1 year
        approved-by: tx-sender,
        conditions: conditions
      })
    ))
  )
)

(define-public (conduct-tower-inspection
  (tower-id uint)
  (inspection-type (string-ascii 30))
  (result (string-ascii 20))
  (violations (string-ascii 200))
  (action-required bool)
)
  (let
    (
      (tower (unwrap! (map-get? cell-towers { tower-id: tower-id }) ERR-TOWER-NOT-FOUND))
      (inspection-id block-height)
    )
    (asserts! (is-authorized-inspector) ERR-NOT-AUTHORIZED)

    ;; Record inspection
    (map-set inspection-records
      { tower-id: tower-id, inspection-id: inspection-id }
      {
        inspection-date: block-height,
        inspector: tx-sender,
        inspection-type: inspection-type,
        result: result,
        violations: violations,
        next-action-required: action-required
      }
    )

    ;; Update tower
    (ok (map-set cell-towers
      { tower-id: tower-id }
      (merge tower {
        last-inspection: block-height,
        next-inspection: (+ block-height u17280),
        status: (if (is-eq result "pass") "operational" "non-compliant")
      })
    ))
  )
)

(define-public (update-tower-status (tower-id uint) (new-status (string-ascii 20)))
  (let
    (
      (tower (unwrap! (map-get? cell-towers { tower-id: tower-id }) ERR-TOWER-NOT-FOUND))
    )
    (asserts! (or (is-contract-owner) (is-eq tx-sender (get owner tower))) ERR-NOT-AUTHORIZED)

    (ok (map-set cell-towers
      { tower-id: tower-id }
      (merge tower { status: new-status })
    ))
  )
)

;; Read-only Functions
(define-read-only (get-tower (tower-id uint))
  (map-get? cell-towers { tower-id: tower-id })
)

(define-read-only (get-tower-permit (tower-id uint))
  (map-get? tower-permits { tower-id: tower-id })
)

(define-read-only (get-inspection-record (tower-id uint) (inspection-id uint))
  (map-get? inspection-records { tower-id: tower-id, inspection-id: inspection-id })
)

(define-read-only (get-total-towers)
  (var-get total-towers)
)

(define-read-only (get-max-tower-height)
  (var-get max-tower-height)
)
