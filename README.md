# OIF Contracts

ERC-7683 compliant OutputCallback and OrderResolver for Compact orders intended for filler consumption.

## Core Contracts

- **OutputCallback**: Executes transaction based on provided callback data.
- **OrderResolverCompact**: Resolver contract to resolve Compact orders into the ERC-7683 format.

## Development

### Setup

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash

# Install dependencies
forge soldeer install

# Run tests
forge test
```
