;; ConsensusHub - Decentralized Decision-Making Platform

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_EXISTS (err u101))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u102))
(define-constant ERR_DECISION_ENDED (err u103))
(define-constant ERR_ALREADY_DECIDED (err u104))
(define-constant ERR_INVALID_OPTION (err u105))
(define-constant ERR_SELF_DELEGATION (err u106))
(define-constant ERR_DELEGATION_CYCLE (err u107))
(define-constant ERR_INVALID_INPUT (err u108))
(define-constant ERR_NOT_ENOUGH_WEIGHT (err u109))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u110))

;; Data Variables
(define-data-var platform-admin principal tx-sender)
(define-data-var cycle-counter uint u0)

;; Maps
(define-map Proposals 
  { proposal-id: uint } 
  { 
    title: (string-ascii 50), 
    options: (list 10 (string-ascii 20)),
    deadline: uint,
    weight-total: uint
  }
)

(define-map Decisions 
  { proposal-id: uint, participant: principal } 
  { option: (string-ascii 20), weight: uint }
)

(define-map ParticipantWeight 
  { participant: principal } 
  { weight: uint }
)

(define-map Delegates
  { grantor: principal }
  { delegate: principal }
)

;; Private Functions
(define-private (is-platform-admin)
  (is-eq tx-sender (var-get platform-admin))
)

(define-private (check-proposal-exists (proposal-id uint))
  (is-some (map-get? Proposals { proposal-id: proposal-id }))
)

(define-private (check-decision-open (proposal-id uint))
  (match (map-get? Proposals { proposal-id: proposal-id })
    proposal-data (< (var-get cycle-counter) (get deadline proposal-data))
    false)
)

(define-private (get-participant-weight (participant principal))
  (default-to u1 (get weight (map-get? ParticipantWeight { participant: participant })))
)

(define-private (update-weight-total (proposal-id uint) (weight uint))
  (match (map-get? Proposals { proposal-id: proposal-id })
    proposal-data (map-set Proposals 
                { proposal-id: proposal-id }
                (merge proposal-data { weight-total: (+ (get weight-total proposal-data) weight) }))
    false)
)

(define-private (validate-string (input (string-ascii 50)))
  (and (>= (len input) u1) (<= (len input) u50))
)

(define-private (validate-options (options (list 10 (string-ascii 20))))
  (and 
    (>= (len options) u2)
    (<= (len options) u10)
    (fold and (map validate-string options) true)
  )
)

(define-private (validate-weight-threshold (participant principal))
  (> (get-participant-weight participant) u0)
)

;; Public Functions
(define-public (create-proposal (title (string-ascii 50)) (options (list 10 (string-ascii 20))) (duration uint))
  (begin
    (asserts! (is-platform-admin) ERR_UNAUTHORIZED)
    (asserts! (validate-string title) ERR_INVALID_INPUT)
    (asserts! (validate-options options) ERR_INVALID_INPUT)
    (asserts! (> duration u0) ERR_INVALID_INPUT)
    (let 
      (
        (proposal-id (+ u1 (default-to u0 (get weight-total (map-get? Proposals { proposal-id: u0 })))))
        (current-cycle (var-get cycle-counter))
      )
      (asserts! (not (check-proposal-exists proposal-id)) ERR_PROPOSAL_EXISTS)
      (ok (map-set Proposals 
            { proposal-id: proposal-id }
            { 
              title: title, 
              options: options,
              deadline: (+ current-cycle duration),
              weight-total: u0
            })))
  )
)

(define-public (submit-decision (proposal-id uint) (option (string-ascii 20)))
  (let 
    (
      (participant-weight (get-participant-weight tx-sender))
      (proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
    )
    (asserts! (check-decision-open proposal-id) ERR_DECISION_ENDED)
    (asserts! (is-some (index-of (get options proposal) option)) ERR_INVALID_OPTION)
    (asserts! (is-none (map-get? Decisions { proposal-id: proposal-id, participant: tx-sender })) ERR_ALREADY_DECIDED)
    (asserts! (validate-weight-threshold tx-sender) ERR_NOT_ENOUGH_WEIGHT)
    (map-set Decisions 
      { proposal-id: proposal-id, participant: tx-sender }
      { option: option, weight: participant-weight })
    (update-weight-total proposal-id participant-weight)
    (ok true)
  )
)

(define-public (assign-delegate (delegate principal))
  (begin
    (asserts! (not (is-eq tx-sender delegate)) ERR_SELF_DELEGATION)
    (asserts! (is-none (map-get? Delegates { grantor: delegate })) ERR_DELEGATION_CYCLE)
    (map-set Delegates { grantor: tx-sender } { delegate: delegate })
    (map-set ParticipantWeight 
      { participant: delegate }
      { weight: (+ (get-participant-weight delegate) (get-participant-weight tx-sender)) })
    (map-delete ParticipantWeight { participant: tx-sender })
    (ok true)
  )
)

(define-public (close-proposal (proposal-id uint))
  (begin
    (asserts! (is-platform-admin) ERR_UNAUTHORIZED)
    (asserts! (check-proposal-exists proposal-id) ERR_PROPOSAL_NOT_FOUND)
    (let ((proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
      (ok (map-set Proposals 
            { proposal-id: proposal-id }
            (merge proposal { deadline: (var-get cycle-counter) })))
    )
  )
)

(define-public (advance-cycle)
  (begin
    (asserts! (is-platform-admin) ERR_UNAUTHORIZED)
    (ok (var-set cycle-counter (+ (var-get cycle-counter) u1)))
  )
)

;; Read-Only Functions
(define-read-only (get-proposal-weight-total (proposal-id uint))
  (ok (get weight-total (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
)

(define-read-only (get-participant-weight-level (participant principal))
  (ok (get-participant-weight participant))
)

(define-read-only (get-proposal-status (proposal-id uint))
  (let ((proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (ok (< (var-get cycle-counter) (get deadline proposal)))
  )
)

(define-read-only (get-current-cycle)
  (ok (var-get cycle-counter))
)

