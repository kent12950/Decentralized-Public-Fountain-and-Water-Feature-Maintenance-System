# Decentralized Public Fountain and Water Feature Maintenance System

A comprehensive blockchain-based system for managing public fountains and water features through smart contracts on the Stacks blockchain.

## Overview

This system provides decentralized management of public fountains through five specialized smart contracts that handle different aspects of fountain maintenance and operation.

## System Architecture

### Core Contracts

1. **Fountain Operations Contract** (`fountain-operations.clar`)
    - Manages seasonal startup and shutdown procedures
    - Tracks operational status and schedules
    - Coordinates fountain activation cycles

2. **Water Quality Monitoring Contract** (`water-quality.clar`)
    - Tests fountain water for safety parameters
    - Monitors and prevents algae growth
    - Maintains water quality standards

3. **Mechanical Systems Contract** (`mechanical-systems.clar`)
    - Manages pumps, filters, and lighting systems
    - Tracks maintenance schedules and component health
    - Handles system diagnostics

4. **Winter Protection Contract** (`winter-protection.clar`)
    - Prepares fountains for freezing weather
    - Manages winterization procedures
    - Coordinates seasonal protection measures

5. **Energy Efficiency Contract** (`energy-efficiency.clar`)
    - Optimizes energy consumption of pumps and lighting
    - Manages power scheduling and efficiency metrics
    - Tracks energy usage patterns

## Key Features

- **Decentralized Management**: No single point of failure
- **Automated Scheduling**: Smart contract-based maintenance cycles
- **Quality Assurance**: Continuous monitoring of water quality and system health
- **Energy Optimization**: Intelligent power management
- **Seasonal Adaptation**: Automatic winter protection protocols

## Data Structures

### Fountain Registry
Each fountain is registered with:
- Unique fountain ID
- Location coordinates
- Installation date
- Capacity and specifications
- Current operational status

### Maintenance Records
- Timestamp of last maintenance
- Type of maintenance performed
- Next scheduled maintenance
- Component replacement history

### Quality Metrics
- Water pH levels
- Chlorine content
- Algae growth indicators
- Safety compliance status

## Installation

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Deploy contracts to testnet/mainnet

## Testing

Run the test suite with:
\`\`\`bash
npm test
\`\`\`

## Usage

### Registering a Fountain
\`\`\`clarity
(contract-call? .fountain-operations register-fountain u1 "Central Park Fountain" u1000)
\`\`\`

### Starting Seasonal Operations
\`\`\`clarity
(contract-call? .fountain-operations start-season u1)
\`\`\`

### Recording Water Quality Test
\`\`\`clarity
(contract-call? .water-quality record-test u1 u7 u2 false)
\`\`\`

## Contract Interactions

Each contract operates independently but maintains data consistency through standardized fountain IDs and status codes.

## Security Considerations

- Only authorized maintenance personnel can perform critical operations
- All actions are logged on-chain for transparency
- Emergency shutdown capabilities for safety

## Contributing

Please read the PR-DETAILS.md file for contribution guidelines and development workflow.

## License

MIT License - see LICENSE file for details
