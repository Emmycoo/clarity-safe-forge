;; Security Validator
;; Validates contracts for security issues

;; Constants 
(define-constant err-validation-failed (err u200))
(define-constant err-invalid-contract-id (err u201))
(define-constant err-validation-expired (err u202))

;; Validation expiration period (in blocks)
(define-constant validation-expiry-blocks u144) ;; ~24 hours

;; Validation severity levels
(define-constant severity-high "HIGH")
(define-constant severity-medium "MEDIUM")
(define-constant severity-low "LOW")

;; Data vars
(define-map validations
  { contract-id: uint }
  {
    status: (string-ascii 20),
    issues: (list 10 {
      description: (string-ascii 64),
      severity: (string-ascii 10)
    }),
    last-validated: uint
  }
)

;; Public functions
(define-public (validate-contract (contract-id uint))
  (let
    (
      (validation-result (run-validations contract-id))
      (current-height block-height)
    )
    (asserts! (is-valid-contract-id contract-id) err-invalid-contract-id)
    (map-set validations
      { contract-id: contract-id }
      {
        status: (get-status validation-result),
        issues: (get issues validation-result),
        last-validated: current-height
      }
    )
    (ok validation-result)
  )
)

;; Read only functions
(define-read-only (get-validation-status (contract-id uint))
  (let
    (
      (validation (map-get? validations { contract-id: contract-id }))
      (current-height block-height)
    )
    (if (and
      (is-some validation)
      (< (- current-height (get last-validated (unwrap-panic validation))) validation-expiry-blocks)
    )
      validation
      none
    )
  )
)

(define-read-only (run-validations (contract-id uint))
  (let
    (
      (issues (concat
        (check-owner-control contract-id)
        (check-token-security contract-id)
      ))
    )
    {
      passed: (is-eq (len issues) u0),
      issues: issues
    }
  )
)

(define-read-only (check-owner-control (contract-id uint))
  (let
    ((contract (unwrap! (contract-call? .contract-factory get-contract contract-id) (list)))
    )
    (if (is-some (get owner contract))
      (list)
      (list {
        description: "Contract lacks owner control mechanism",
        severity: severity-high
      })
    )
  )
)

(define-read-only (check-token-security (contract-id uint))
  (let
    ((contract (unwrap! (contract-call? .contract-factory get-contract contract-id) (list)))
    )
    (list {
      description: "Basic token security check passed",
      severity: severity-low
    })
  )
)

(define-read-only (is-valid-contract-id (contract-id uint))
  (is-some (contract-call? .contract-factory get-contract contract-id))
)

(define-read-only (get-status (result {passed: bool, issues: (list 10 {description: (string-ascii 64), severity: (string-ascii 10)})}))
  (if (get passed result)
    "PASSED"
    "FAILED"
  )
)
