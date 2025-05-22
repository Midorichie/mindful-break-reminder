;; Mindful Break Reminder Contract - Phase 2
;; Enhanced with security, bug fixes, and new functionality

;; Constants for error codes
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-INTERVAL (err u102))
(define-constant ERR-TOO-EARLY (err u103))
(define-constant ERR-USER-NOT-FOUND (err u104))
(define-constant ERR-INVALID-STREAK (err u105))

;; Data variables
(define-data-var break-interval uint u3600) ;; default 1 hour
(define-data-var contract-owner principal tx-sender)
(define-data-var total-users uint u0)

;; Data maps
(define-map breaks 
  principal 
  {last-break: uint, streak: uint, total-breaks: uint})

(define-map user-settings 
  principal 
  {custom-interval: uint, notifications-enabled: bool, break-goal: uint})

(define-map break-history 
  {user: principal, break-id: uint} 
  {timestamp: uint, duration: uint, break-type: (string-ascii 20)})

;; Read-only functions
(define-read-only (get-break-interval)
  (var-get break-interval))

(define-read-only (get-user-break-info (user principal))
  (map-get? breaks user))

(define-read-only (get-user-settings (user principal))
  (map-get? user-settings user))

(define-read-only (get-total-users)
  (var-get total-users))

(define-read-only (time-until-next-break (user principal))
  (let ((user-data (map-get? breaks user)))
    (match user-data
      break-info 
        (let ((last-break (get last-break break-info))
              (interval (get-user-interval user))
              (current-height burn-block-height))
          (let ((blocks-passed (- current-height last-break)))
            (if (>= blocks-passed interval)
              u0
              (- interval blocks-passed))))
      u0)))

(define-read-only (get-user-interval (user principal))
  (let ((settings (map-get? user-settings user)))
    (match settings
      user-config (get custom-interval user-config)
      (var-get break-interval))))

(define-read-only (is-break-due (user principal))
  (let ((time-left (time-until-next-break user)))
    (is-eq time-left u0)))

;; Public functions
(define-public (set-global-interval (seconds uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= seconds u60) (<= seconds u86400)) ERR-INVALID-INTERVAL) ;; 1 minute to 24 hours
    (var-set break-interval seconds)
    (ok seconds)))

(define-public (set-user-interval (seconds uint))
  (begin
    (asserts! (and (>= seconds u60) (<= seconds u86400)) ERR-INVALID-INTERVAL)
    (let ((current-settings (default-to 
                              {custom-interval: (var-get break-interval), 
                               notifications-enabled: true, 
                               break-goal: u8} 
                              (map-get? user-settings tx-sender))))
      (map-set user-settings 
        tx-sender 
        (merge current-settings {custom-interval: seconds}))
      (ok seconds))))

(define-public (touch-in)
  (let ((current-height burn-block-height)
        (current-data (map-get? breaks tx-sender)))
    (match current-data
      existing-data
        (let ((new-streak (+ (get streak existing-data) u1))
              (new-total (+ (get total-breaks existing-data) u1)))
          (map-set breaks 
            tx-sender 
            {last-break: current-height, streak: new-streak, total-breaks: new-total})
          (ok {timestamp: current-height, streak: new-streak}))
      ;; First time user
      (begin
        (map-set breaks 
          tx-sender 
          {last-break: current-height, streak: u1, total-breaks: u1})
        (var-set total-users (+ (var-get total-users) u1))
        (ok {timestamp: current-height, streak: u1})))))

(define-public (take-break (duration uint) (break-type (string-ascii 20)))
  (let ((user-data (unwrap! (map-get? breaks tx-sender) ERR-USER-NOT-FOUND))
        (break-id (get total-breaks user-data)))
    (asserts! (> duration u0) (err u107))
    (asserts! (<= duration u7200) (err u108)) ;; max 2 hours
    (map-set break-history 
      {user: tx-sender, break-id: break-id} 
      {timestamp: burn-block-height, 
       duration: duration, 
       break-type: break-type})
    (ok break-id)))

(define-public (set-break-goal (goal uint))
  (begin
    (asserts! (and (> goal u0) (<= goal u50)) ERR-INVALID-STREAK) ;; reasonable daily goal
    (let ((current-settings (default-to 
                              {custom-interval: (var-get break-interval), 
                               notifications-enabled: true, 
                               break-goal: u8} 
                              (map-get? user-settings tx-sender))))
      (map-set user-settings 
        tx-sender 
        (merge current-settings {break-goal: goal}))
      (ok goal))))

(define-public (toggle-notifications)
  (let ((current-settings (default-to 
                            {custom-interval: (var-get break-interval), 
                             notifications-enabled: true, 
                             break-goal: u8} 
                            (map-get? user-settings tx-sender)))
        (new-status (not (get notifications-enabled current-settings))))
    (map-set user-settings 
      tx-sender 
      (merge current-settings {notifications-enabled: new-status}))
    (ok new-status)))

(define-public (reset-streak)
  (let ((user-data (unwrap! (map-get? breaks tx-sender) ERR-USER-NOT-FOUND)))
    (map-set breaks 
      tx-sender 
      (merge user-data {streak: u0}))
    (ok u0)))

;; Admin functions
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set contract-owner new-owner)
    (ok new-owner)))
