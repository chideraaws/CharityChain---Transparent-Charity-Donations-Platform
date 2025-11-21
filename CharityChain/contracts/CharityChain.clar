;; CharityChain - Transparent Charity Donations Platform
;; Track donations, fund allocation, and impact with full transparency

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-goal-reached (err u104))

(define-data-var next-campaign-id uint u1)
(define-data-var next-donation-id uint u1)
(define-data-var total-donations uint u0)
(define-data-var total-campaigns uint u0)

(define-map campaigns
  uint
  {
    charity: principal,
    title: (string-ascii 128),
    description: (string-ascii 512),
    goal-amount: uint,
    raised-amount: uint,
    beneficiary: principal,
    deadline: uint,
    category: (string-ascii 32),
    active: bool,
    verified: bool,
    created-at: uint
  }
)

(define-map donations
  uint
  {
    campaign-id: uint,
    donor: principal,
    amount: uint,
    anonymous: bool,
    message: (string-ascii 256),
    timestamp: uint
  }
)

(define-map donor-history
  principal
  {
    total-donated: uint,
    campaigns-supported: uint,
    largest-donation: uint
  }
)

(define-map fund-allocations
  {campaign-id: uint, allocation-id: uint}
  {
    purpose: (string-ascii 256),
    amount: uint,
    recipient: principal,
    allocated-at: uint,
    proof-hash: (string-ascii 64)
  }
)

(define-public (create-campaign
    (title (string-ascii 128))
    (description (string-ascii 512))
    (goal-amount uint)
    (beneficiary principal)
    (deadline uint)
    (category (string-ascii 32)))
  (let ((campaign-id (var-get next-campaign-id)))
    (asserts! (> goal-amount u0) err-invalid-amount)
    (asserts! (> deadline block-height) err-invalid-amount)

    (map-set campaigns campaign-id {
      charity: tx-sender,
      title: title,
      description: description,
      goal-amount: goal-amount,
      raised-amount: u0,
      beneficiary: beneficiary,
      deadline: deadline,
      category: category,
      active: true,
      verified: false,
      created-at: block-height
    })

    (var-set next-campaign-id (+ campaign-id u1))
    (var-set total-campaigns (+ (var-get total-campaigns) u1))
    (print {event: "campaign-created", campaign-id: campaign-id})
    (ok campaign-id)
  )
)

(define-public (donate (campaign-id uint) (amount uint) (anonymous bool) (message (string-ascii 256)))
  (let (
    (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
    (donation-id (var-get next-donation-id))
    (donor-stats (default-to {total-donated: u0, campaigns-supported: u0, largest-donation: u0}
      (map-get? donor-history tx-sender)))
  )
    (asserts! (get active campaign) err-unauthorized)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (< (get raised-amount campaign) (get goal-amount campaign)) err-goal-reached)

    (map-set donations donation-id {
      campaign-id: campaign-id,
      donor: tx-sender,
      amount: amount,
      anonymous: anonymous,
      message: message,
      timestamp: block-height
    })

    (map-set campaigns campaign-id
      (merge campaign {raised-amount: (+ (get raised-amount campaign) amount)}))

    (map-set donor-history tx-sender {
      total-donated: (+ (get total-donated donor-stats) amount),
      campaigns-supported: (+ (get campaigns-supported donor-stats) u1),
      largest-donation: (if (> amount (get largest-donation donor-stats))
        amount
        (get largest-donation donor-stats))
    })

    (var-set next-donation-id (+ donation-id u1))
    (var-set total-donations (+ (var-get total-donations) amount))
    (print {event: "donation-made", campaign-id: campaign-id, amount: amount})
    (ok donation-id)
  )
)

(define-public (verify-campaign (campaign-id uint))
  (let ((campaign (unwrap! (map-get? campaigns campaign-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set campaigns campaign-id (merge campaign {verified: true}))
    (print {event: "campaign-verified", campaign-id: campaign-id})
    (ok true)
  )
)

(define-read-only (get-campaign (campaign-id uint))
  (map-get? campaigns campaign-id)
)

(define-read-only (get-donation (donation-id uint))
  (map-get? donations donation-id)
)

(define-read-only (get-donor-stats (donor principal))
  (map-get? donor-history donor)
)

(define-read-only (get-platform-stats)
  (ok {
    total-donations: (var-get total-donations),
    total-campaigns: (var-get total-campaigns)
  })
)

(define-public (end-campaign (campaign-id uint))
  (let ((campaign (unwrap! (map-get? campaigns campaign-id) err-not-found)))
    (asserts! (is-eq tx-sender (get charity campaign)) err-unauthorized)
    (asserts! (get active campaign) err-unauthorized)

    (map-set campaigns campaign-id (merge campaign {active: false}))

    (print {event: "campaign-ended", campaign-id: campaign-id})
    (ok true)
  )
)

(define-public (extend-campaign (campaign-id uint) (new-end-date uint))
  (let ((campaign (unwrap! (map-get? campaigns campaign-id) err-not-found)))
    (asserts! (is-eq tx-sender (get charity campaign)) err-unauthorized)
    (asserts! (> new-end-date (get deadline campaign)) err-invalid-amount)

    (map-set campaigns campaign-id (merge campaign {deadline: new-end-date}))

    (print {event: "campaign-extended", campaign-id: campaign-id, new-end-date: new-end-date})
    (ok true)
  )
)

(define-public (update-campaign-goal (campaign-id uint) (new-goal uint))
  (let ((campaign (unwrap! (map-get? campaigns campaign-id) err-not-found)))
    (asserts! (is-eq tx-sender (get charity campaign)) err-unauthorized)
    (asserts! (> new-goal u0) err-invalid-amount)

    (map-set campaigns campaign-id (merge campaign {goal-amount: new-goal}))

    (print {event: "campaign-goal-updated", campaign-id: campaign-id, new-goal: new-goal})
    (ok true)
  )
)

(define-public (withdraw-funds (campaign-id uint))
  (let ((campaign (unwrap! (map-get? campaigns campaign-id) err-not-found)))
    (asserts! (is-eq tx-sender (get charity campaign)) err-unauthorized)
    (asserts! (or (not (get active campaign)) (>= block-height (get deadline campaign))) err-unauthorized)

    (let ((amount (get raised-amount campaign)))
      (map-set campaigns campaign-id (merge campaign {raised-amount: u0}))

      (print {event: "funds-withdrawn", campaign-id: campaign-id, amount: amount, beneficiary: (get beneficiary campaign)})
      (ok amount)
    )
  )
)

(define-read-only (get-campaign-progress (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (ok {
      raised: (get raised-amount campaign),
      goal: (get goal-amount campaign),
      percentage: (if (is-eq (get goal-amount campaign) u0)
        u0
        (/ (* (get raised-amount campaign) u100) (get goal-amount campaign)))
    })
    err-not-found
  )
)

(define-read-only (is-campaign-successful (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (ok (>= (get raised-amount campaign) (get goal-amount campaign)))
    err-not-found
  )
)
