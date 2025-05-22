(define-data-var break-interval uint u3600) ; default 1 hour
(define-map breaks ((user principal)) ((last-break timestamp)))

(define-public (set-interval (seconds uint))
  (begin
    (asserts! (>= seconds u60) (err u100)) ; at least 1 minute
    (var-set break-interval seconds)
    (ok seconds)))

(define-public (touch-in)
  (let ((now (block-height)))
    (map-set breaks {user: tx-sender} {last-break: now})
    (ok now)))
