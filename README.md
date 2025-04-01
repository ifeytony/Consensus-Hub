# Consensus Hub

A decentralized platform for collective decision-making and governance on the blockchain.

## Overview

Consensus Hub is a smart contract system that enables organizations to create proposals, gather weighted decisions from participants, and reach consensus in a transparent and verifiable way. The platform supports delegation of decision-making power, time-bound proposals, and weighted voting to ensure fair representation.

## Features

- **Proposal Management**: Create and manage decision proposals with multiple options
- **Weighted Decision-Making**: Participants' decisions carry weight based on their stake or delegation
- **Delegation System**: Participants can delegate their decision-making power to trusted representatives
- **Cycle-Based Timing**: Proposals have deadlines based on platform cycles for predictable governance
- **Transparent Tallying**: All decisions and their weights are recorded on the blockchain for verification

## Core Functions

### Administrative Functions

- `create-proposal`: Create a new decision proposal with multiple options
- `close-proposal`: End a proposal early if needed
- `advance-cycle`: Move the platform forward to the next governance cycle

### Participant Functions

- `submit-decision`: Cast a weighted decision on an open proposal
- `assign-delegate`: Delegate decision-making power to another participant

### Read-Only Functions

- `get-proposal-weight-total`: View the total weight of decisions for a proposal
- `get-participant-weight-level`: Check a participant's decision-making weight
- `get-proposal-status`: Verify if a proposal is still open for decisions
- `get-current-cycle`: Get the current governance cycle number

## Technical Details

- Proposals can have between 2 and 10 options
- Each participant starts with a base weight of 1
- Delegation increases a delegate's weight by the grantor's weight
- Proposals automatically close when their deadline cycle is reached
- The platform admin can create proposals and advance cycles

## Getting Started

1. Deploy the contract to your blockchain
2. Set up initial participant weights if needed
3. Create proposals for decisions
4. Participants submit their decisions or delegate their weight
5. After the deadline, tally the results to determine the winning option

## Security

The system includes safeguards against common governance issues:
- Prevention of self-delegation
- Protection against delegation cycles
- Validation of all inputs
- Authorization checks for administrative functions
