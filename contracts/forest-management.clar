;; Forest Management Contract
;; Records sustainable harvesting practices

(define-data-var admin principal tx-sender)

;; Forest plot structure
(define-map forest-plots
  { plot-id: uint }
  {
    owner: principal,
    area: uint,
    location: (string-utf8 100),
    last-audit-date: uint,
    sustainable-status: bool
  }
)

;; Harvesting records
(define-map harvesting-records
  { record-id: uint }
  {
    plot-id: uint,
    harvest-date: uint,
    volume: uint,
    species: (string-utf8 50),
    sustainable-methods-used: bool
  }
)

(define-data-var next-plot-id uint u1)
(define-data-var next-record-id uint u1)

;; Register a new forest plot
(define-public (register-forest-plot
                (area uint)
                (location (string-utf8 100)))
  (let ((plot-id (var-get next-plot-id)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set forest-plots
        { plot-id: plot-id }
        {
          owner: tx-sender,
          area: area,
          location: location,
          last-audit-date: block-height,
          sustainable-status: false
        }
      )
      (var-set next-plot-id (+ plot-id u1))
      (ok plot-id)
    )
  )
)

;; Record a harvesting activity
(define-public (record-harvesting
                (plot-id uint)
                (volume uint)
                (species (string-utf8 50))
                (sustainable-methods-used bool))
  (let ((record-id (var-get next-record-id))
        (plot (unwrap! (map-get? forest-plots { plot-id: plot-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (get owner plot)) (err u403))
      (map-set harvesting-records
        { record-id: record-id }
        {
          plot-id: plot-id,
          harvest-date: block-height,
          volume: volume,
          species: species,
          sustainable-methods-used: sustainable-methods-used
        }
      )
      (var-set next-record-id (+ record-id u1))
      (ok record-id)
    )
  )
)

;; Update sustainable status after audit
(define-public (update-sustainable-status (plot-id uint) (status bool))
  (let ((plot (unwrap! (map-get? forest-plots { plot-id: plot-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set forest-plots
        { plot-id: plot-id }
        (merge plot {
          last-audit-date: block-height,
          sustainable-status: status
        })
      )
      (ok true)
    )
  )
)

;; Read-only function to get plot details
(define-read-only (get-forest-plot (plot-id uint))
  (map-get? forest-plots { plot-id: plot-id })
)

;; Read-only function to get harvesting record
(define-read-only (get-harvesting-record (record-id uint))
  (map-get? harvesting-records { record-id: record-id })
)

;; Transfer ownership of a forest plot
(define-public (transfer-plot-ownership (plot-id uint) (new-owner principal))
  (let ((plot (unwrap! (map-get? forest-plots { plot-id: plot-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (get owner plot)) (err u403))
      (map-set forest-plots
        { plot-id: plot-id }
        (merge plot { owner: new-owner })
      )
      (ok true)
    )
  )
)
