;; Project Verification Contract
;; Validates development initiatives and their legitimacy

(define-data-var admin principal tx-sender)

;; Project status enum: 0=pending, 1=verified, 2=rejected
(define-map projects
  { project-id: uint }
  {
    owner: principal,
    name: (string-utf8 100),
    description: (string-utf8 500),
    location: (string-utf8 100),
    status: uint,
    verification-date: uint
  }
)

(define-data-var project-counter uint u0)

;; Read-only function to get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Register a new project (pending verification)
(define-public (register-project (name (string-utf8 100)) (description (string-utf8 500)) (location (string-utf8 100)))
  (let ((new-id (var-get project-counter)))
    (begin
      (map-set projects
        { project-id: new-id }
        {
          owner: tx-sender,
          name: name,
          description: description,
          location: location,
          status: u0,
          verification-date: u0
        }
      )
      (var-set project-counter (+ new-id u1))
      (ok new-id)
    )
  )
)

;; Verify a project (admin only)
(define-public (verify-project (project-id uint))
  (if (is-eq tx-sender (var-get admin))
    (match (map-get? projects { project-id: project-id })
      project (begin
        (map-set projects
          { project-id: project-id }
          (merge project {
            status: u1,
            verification-date: block-height
          })
        )
        (ok true)
      )
      (err u1) ;; Project not found
    )
    (err u403) ;; Unauthorized
  )
)

;; Reject a project (admin only)
(define-public (reject-project (project-id uint))
  (if (is-eq tx-sender (var-get admin))
    (match (map-get? projects { project-id: project-id })
      project (begin
        (map-set projects
          { project-id: project-id }
          (merge project {
            status: u2,
            verification-date: block-height
          })
        )
        (ok true)
      )
      (err u1) ;; Project not found
    )
    (err u403) ;; Unauthorized
  )
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (begin
      (var-set admin new-admin)
      (ok true)
    )
    (err u403) ;; Unauthorized
  )
)
