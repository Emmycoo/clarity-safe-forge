;; Contract Factory
;; Handles creating and deploying new contracts

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-template (err u101))
(define-constant err-deploy-failed (err u102))

;; Data vars
(define-data-var next-contract-id uint u0)
(define-map contracts 
  { contract-id: uint }
  { 
    owner: principal,
    template-id: uint,
    timestamp: uint,
    status: (string-ascii 20)
  }
)

;; Public functions
(define-public (create-contract (template-id uint))
  (let
    (
      (contract-id (var-get next-contract-id))
    )
    (asserts! (is-valid-template template-id) err-invalid-template)
    (map-insert contracts
      { contract-id: contract-id }
      {
        owner: tx-sender,
        template-id: template-id, 
        timestamp: block-height,
        status: "CREATED"
      }
    )
    (var-set next-contract-id (+ contract-id u1))
    (ok contract-id)
  )
)

(define-public (deploy-contract (contract-id uint))
  (let
    (
      (contract (unwrap! (get-contract contract-id) err-deploy-failed))
    )
    (asserts! (is-contract-owner contract-id) err-not-authorized)
    ;; Deployment logic here
    (ok true)
  )
)

;; Read only functions
(define-read-only (get-contract (contract-id uint))
  (map-get? contracts { contract-id: contract-id })
)

(define-read-only (is-contract-owner (contract-id uint))
  (let
    (
      (contract (unwrap! (get-contract contract-id) false))
    )
    (is-eq (get owner contract) tx-sender)
  )
)

(define-read-only (is-valid-template (template-id uint))
  (< template-id u5) ;; Currently supporting 5 templates
)
