# CharityChain - Transparent Charity Donations Platform

A blockchain-based charitable giving platform that brings transparency, accountability, and trust to philanthropic activities through immutable on-chain donation tracking.

## Overview

CharityChain enables charities to create fundraising campaigns, donors to contribute with full transparency, and all participants to track fund allocation and impact in real-time. Every donation is permanently recorded on the blockchain, ensuring complete accountability.

## Features

### Core Functionality
- **Campaign Management**: Create time-bound fundraising campaigns with goals
- **Transparent Donations**: All contributions recorded immutably on-chain
- **Anonymous Giving**: Optional anonymous donation support
- **Donor Recognition**: Comprehensive donation history tracking
- **Verification System**: Campaign verification by platform administrators
- **Fund Withdrawal**: Secure withdrawal to designated beneficiaries
- **Progress Tracking**: Real-time campaign progress monitoring
- **Flexible Management**: Update goals, extend deadlines, end campaigns

### Key Features
- ✅ Complete donation transparency and traceability
- ✅ Anonymous donation option for privacy
- ✅ Donor impact tracking (lifetime statistics)
- ✅ Campaign verification for legitimacy
- ✅ Deadline-based fundraising periods
- ✅ Category-based campaign organization
- ✅ Personal message support with donations
- ✅ Goal-based campaign success metrics

## Contract Architecture

### Data Structures

#### Campaigns
Core fundraising campaign information:
- Charity organization (principal)
- Title and description
- Goal amount and raised amount
- Beneficiary principal (fund recipient)
- Deadline (block height)
- Category (e.g., "Healthcare", "Education", "Disaster Relief")
- Active and verified status flags
- Creation timestamp

#### Donations
Individual contribution records:
- Associated campaign ID
- Donor principal
- Donation amount
- Anonymous flag
- Personal message (up to 256 characters)
- Timestamp

#### Donor History
Lifetime donor statistics:
- Total amount donated across all campaigns
- Number of campaigns supported
- Largest single donation

#### Fund Allocations
Transparent fund usage tracking (data structure defined but functions not yet implemented):
- Purpose description
- Amount allocated
- Recipient
- Allocation timestamp
- Proof hash for documentation

## Public Functions

### Campaign Management

#### `create-campaign`
```clarity
(create-campaign
  (title (string-ascii 128))
  (description (string-ascii 512))
  (goal-amount uint)
  (beneficiary principal)
  (deadline uint)
  (category (string-ascii 32)))
```
Create a new fundraising campaign. Any principal can create campaigns.

**Parameters**:
- `goal-amount`: Target fundraising amount in micro-STX
- `beneficiary`: Principal that will receive withdrawn funds
- `deadline`: Block height when campaign ends
- `category`: Classification like "Healthcare", "Education", "Environment"

**Validations**:
- Goal amount must be greater than 0
- Deadline must be in the future

**Returns**: `(ok campaign-id)`

#### `verify-campaign`
```clarity
(verify-campaign (campaign-id uint))
```
Verify a campaign's legitimacy. **Owner-only function.** Verified campaigns build donor trust.

**Returns**: `(ok true)`

#### `end-campaign`
```clarity
(end-campaign (campaign-id uint))
```
Manually end an active campaign before the deadline. Only the campaign creator can end their campaigns.

**Returns**: `(ok true)`

#### `extend-campaign`
```clarity
(extend-campaign 
  (campaign-id uint)
  (new-end-date uint))
```
Extend a campaign's deadline. New deadline must be later than current deadline.

**Returns**: `(ok true)`

#### `update-campaign-goal`
```clarity
(update-campaign-goal
  (campaign-id uint)
  (new-goal uint))
```
Adjust the campaign's fundraising goal. Only the campaign creator can update.

**Returns**: `(ok true)`

### Donations

#### `donate`
```clarity
(donate
  (campaign-id uint)
  (amount uint)
  (anonymous bool)
  (message (string-ascii 256)))
```
Make a donation to an active campaign. Records the donation and updates all relevant statistics.

**Parameters**:
- `amount`: Donation amount in micro-STX
- `anonymous`: If true, donor identity hidden from public queries
- `message`: Optional personal message (e.g., "In memory of...", "Keep up the great work!")

**Validations**:
- Campaign must be active
- Amount must be greater than 0
- Campaign must not have reached its goal

**Effects**:
- Records donation with timestamp
- Updates campaign raised amount
- Updates donor statistics (total donated, campaigns supported, largest donation)
- Increments global donation counter

**Returns**: `(ok donation-id)`

### Fund Management

#### `withdraw-funds`
```clarity
(withdraw-funds (campaign-id uint))
```
Withdraw raised funds to the designated beneficiary. Only the campaign creator can withdraw.

**Conditions**:
- Campaign must be ended OR deadline must have passed
- Only charity that created the campaign can withdraw

**Effects**:
- Resets raised amount to 0
- Emits withdrawal event with amount and beneficiary

**Returns**: `(ok amount)` - Amount withdrawn

## Read-Only Functions

### `get-campaign`
```clarity
(get-campaign (campaign-id uint))
```
Retrieve complete campaign information including progress.

### `get-donation`
```clarity
(get-donation (donation-id uint))
```
Retrieve donation details. Returns all donation information including donor (unless querying mechanism respects anonymous flag).

### `get-donor-stats`
```clarity
(get-donor-stats (donor principal))
```
Get lifetime statistics for a donor:
- Total donated across all campaigns
- Number of campaigns supported
- Largest single donation

### `get-platform-stats`
```clarity
(get-platform-stats)
```
Get global platform statistics:
- Total donation volume (all-time)
- Total number of campaigns created

### `get-campaign-progress`
```clarity
(get-campaign-progress (campaign-id uint))
```
Calculate campaign progress metrics:
- Amount raised
- Goal amount
- Percentage of goal reached

**Returns**: `(ok {raised: uint, goal: uint, percentage: uint})`

### `is-campaign-successful`
```clarity
(is-campaign-successful (campaign-id uint))
```
Check if campaign has reached its fundraising goal.

**Returns**: `(ok bool)` - True if raised ≥ goal

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-owner-only` | Action restricted to contract owner |
| u101 | `err-not-found` | Campaign or resource not found |
| u102 | `err-unauthorized` | Caller not authorized for action |
| u103 | `err-invalid-amount` | Invalid amount or parameter value |
| u104 | `err-goal-reached` | Campaign has already reached its goal |

## Events

The contract emits events for all major actions:
- `campaign-created`: New campaign registered
- `campaign-verified`: Campaign verified by owner
- `donation-made`: New donation received
- `campaign-ended`: Campaign manually ended
- `campaign-extended`: Deadline extended
- `campaign-goal-updated`: Goal amount changed
- `funds-withdrawn`: Funds sent to beneficiary

## Usage Examples

### Create a Fundraising Campaign
```clarity
;; Create campaign for disaster relief
(contract-call? .charity-chain create-campaign
  "Hurricane Relief Fund 2024"
  "Providing emergency aid and rebuilding support for hurricane victims"
  u100000000000  ;; 100,000 STX goal
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; Beneficiary
  u52560         ;; ~1 year from now (52,560 blocks)
  "Disaster Relief")

;; Owner verifies the campaign
(contract-call? .charity-chain verify-campaign u1)
```

### Make Donations
```clarity
;; Public donation with message
(contract-call? .charity-chain donate
  u1                    ;; campaign-id
  u10000000            ;; 10 STX donation
  false                ;; Not anonymous
  "Happy to help!")    ;; Personal message

;; Anonymous donation
(contract-call? .charity-chain donate
  u1
  u50000000            ;; 50 STX
  true                 ;; Anonymous
  "")                  ;; No message
```

### Campaign Management
```clarity
;; Extend campaign deadline
(contract-call? .charity-chain extend-campaign
  u1
  u78840)  ;; Extend by ~6 months

;; Update goal if needed
(contract-call? .charity-chain update-campaign-goal
  u1
  u150000000000)  ;; Increase to 150,000 STX

;; Check progress
(contract-call? .charity-chain get-campaign-progress u1)
;; Returns: {raised: u75000000000, goal: u150000000000, percentage: u50}

;; End campaign early if goal reached
(contract-call? .charity-chain end-campaign u1)
```

### Withdraw Funds
```clarity
;; After deadline or manual end, charity withdraws funds
(contract-call? .charity-chain withdraw-funds u1)
;; Returns: (ok u75000000000) and emits withdrawal event
```

### Query Donor Statistics
```clarity
;; Check lifetime donor stats
(contract-call? .charity-chain get-donor-stats 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
;; Returns: {total-donated: u150000000, campaigns-supported: u5, largest-donation: u50000000}
```

## Transparency Features

### On-Chain Accountability
Every transaction is immutably recorded:
- **Who**: Donor principal (unless anonymous)
- **What**: Exact donation amount
- **When**: Block height timestamp
- **Where**: Specific campaign
- **Why**: Optional personal message

### Campaign Verification
The verification system helps donors identify legitimate campaigns:
- ✅ **Verified**: Campaign reviewed and approved by platform
- ⚠️ **Unverified**: New or pending review

### Progress Tracking
Real-time transparency on campaign performance:
- Current amount raised vs. goal
- Percentage completion
- Success status
- Time remaining (based on deadline)

## Trust & Safety

### Fraud Prevention
- Campaign verification by trusted administrators
- Immutable donation records (cannot be altered)
- Public campaign information for due diligence
- Withdrawal restrictions (deadline or manual end required)

### Donor Protection
- Anonymous donation option for privacy
- Transparent fund allocation (future enhancement)
- Permanent donation receipts on blockchain
- Campaign progress visibility

### Charity Accountability
- Cannot withdraw until campaign ends or deadline passes
- All withdrawals permanently recorded
- Beneficiary address publicly visible
- Fund allocation tracking (structure ready for implementation)

## Campaign Categories

Suggested categories for organization:
- **Healthcare**: Medical treatments, hospital support
- **Education**: Schools, scholarships, educational materials
- **Disaster Relief**: Emergency response, rebuilding efforts
- **Environment**: Conservation, climate action, wildlife
- **Poverty Alleviation**: Food banks, housing, job training
- **Arts & Culture**: Museums, performances, cultural preservation
- **Animal Welfare**: Shelters, rescue operations, veterinary care
- **Research**: Scientific research, disease cures
- **Community Development**: Infrastructure, local projects

## Platform Economics

### No Platform Fees
The current implementation does not charge platform fees. All donations go entirely to campaigns.

### Potential Revenue Models (Future)
- Optional platform fee percentage
- Premium features for verified charities
- Sponsored campaign placements
- Grant matching programs

## Donor Recognition

### Lifetime Statistics
The platform tracks donor impact:
- **Total Donated**: Aggregate giving across all campaigns
- **Campaigns Supported**: Number of different causes supported
- **Largest Donation**: Biggest single contribution

### Recognition Tiers (Suggested)
- 🥉 **Supporter**: 1-5 campaigns supported
- 🥈 **Advocate**: 6-20 campaigns supported
- 🥇 **Champion**: 21+ campaigns supported
- 💎 **Philanthropist**: Total donated > threshold

## Security Considerations

### Authorization Controls
✅ Only campaign creators can:
- End their campaigns
- Extend deadlines
- Update goals
- Withdraw funds

✅ Only contract owner can:
- Verify campaigns

### Financial Safety
✅ Withdrawals only possible when:
- Campaign is manually ended, OR
- Deadline has been reached

✅ Donations protected:
- Must be to active campaigns
- Must be positive amounts
- Campaign cannot exceed goal (blocks donations once goal reached)

## Integration Patterns

### Website Integration
```javascript
// Check campaign progress
const progress = await contract.getProgress(campaignId);
const percentComplete = progress.percentage;

// Display donation leaderboard (non-anonymous donors)
const donations = await contract.queryDonations(campaignId);
const topDonors = donations.sort((a, b) => b.amount - a.amount);
```

### Mobile App Integration
```javascript
// Real-time campaign updates
watchContract('campaign-created', (event) => {
  notifyUsers(event.campaignId);
});

watchContract('donation-made', (event) => {
  updateCampaignUI(event.campaignId);
});
```

### Social Media Sharing
```javascript
// Generate shareable donation receipt
const donation = await contract.getDonation(donationId);
const shareText = `I just donated ${donation.amount} STX to ${campaign.title}! 
Join me in supporting this cause on CharityChain.`;
```

## Future Enhancements

### Phase 2 Features
- [ ] Fund allocation tracking implementation
- [ ] Milestone-based fund release
- [ ] Recurring donation support
- [ ] Campaign updates and news feed
- [ ] Donor badges and achievements

### Phase 3 Features
- [ ] Multi-signature withdrawals for large campaigns
- [ ] Grant matching program infrastructure
- [ ] Impact reporting with proof uploads
- [ ] Campaign comments and community engagement
- [ ] Charity reputation scores

### Advanced Features
- [ ] DAO governance for dispute resolution
- [ ] Integration with fiat payment providers
- [ ] Tax receipt generation
- [ ] Fundraising team support (multiple admins)
- [ ] Campaign templates for quick setup

## Compliance & Regulations

### Considerations
- Charities should comply with local fundraising regulations
- Tax-exempt status verification outside of smart contract
- Know Your Customer (KYC) for large donations (if required)
- Anti-Money Laundering (AML) compliance
- Charitable solicitation registration where required

### Recommended Practices
- Maintain off-chain charity verification documentation
- Provide detailed campaign descriptions and goals
- Regular impact reporting to donors
- Transparent communication about fund usage
- Annual financial reporting

## Development

### Prerequisites
- Clarinet CLI
- Stacks blockchain node
- Understanding of charitable operations

### Testing
```bash
clarinet test
```

### Local Development
```bash
clarinet console
```

### Deployment
```bash
clarinet deploy --network mainnet
```

## Testing Checklist

- [ ] Campaign creation with various parameters
- [ ] Donation flow with anonymous and public donations
- [ ] Campaign verification by owner
- [ ] Deadline enforcement for withdrawals
- [ ] Goal update and extension functionality
- [ ] Donor statistics accumulation
- [ ] Edge case: Donation when goal almost reached
- [ ] Edge case: Multiple campaigns per charity
- [ ] Event emission verification

## Real-World Impact

CharityChain enables:
- **🔍 Transparency**: Donors see exactly where funds go
- **💰 Lower Costs**: Blockchain reduces administrative overhead
- **🌍 Global Reach**: Anyone with cryptocurrency can donate
- **⚡ Speed**: Instant donations without banking delays
- **📊 Accountability**: Permanent record of all transactions
- **🤝 Trust**: Cryptographic verification builds confidence

## Contributing

We welcome contributions! Areas of focus:
- Fund allocation tracking implementation
- Enhanced verification mechanisms
- Impact reporting features
- UI/UX improvements for donor engagement
- Integration guides and SDKs

## Resources

- [Charity Compliance Guide](https://example.com/charity-compliance)
- [Stacks Documentation](https://docs.stacks.co)
- [Blockchain for Nonprofits](https://example.com/blockchain-nonprofits)

## License

MIT License

---

**Contract Version**: 1.0.0  
**Network**: Stacks Blockchain  
**Language**: Clarity  
**Purpose**: Transparent Charitable Giving
