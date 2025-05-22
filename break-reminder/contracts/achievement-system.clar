
;; Achievement System Contract
;; Companion contract for mindful break reminders

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u201))
(define-constant ERR-ACHIEVEMENT-EXISTS (err u202))
(define-constant ERR-ACHIEVEMENT-NOT-FOUND (err u203))
(define-constant ERR-ALREADY-EARNED (err u204))
(define-constant ERR-REQUIREMENTS-NOT-MET (err u205))

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var next-achievement-id uint u1)

;; Achievement types
(define-map achievements
  uint
  {name: (string-ascii 50),
   description: (string-ascii 200),
   requirement-type: (string-ascii 20), ;; "streak", "total", "consistency"
   requirement-value: uint,
   reward-points: uint,
   created-at: uint})

;; User achievements
(define-map user-achievements
  {user: principal, achievement-id: uint}
  {earned-at: uint, points-awarded: uint})

;; User stats
(define-map user-stats
  principal
  {total-points: uint, achievements-count: uint, last-updated: uint})

;; Predefined achievements data
(define-map achievement-templates
  uint
  {name: (string-ascii 50),
   description: (string-ascii 200),
   requirement-type: (string-ascii 20),
   requirement-value: uint,
   reward-points: uint})

;; Initialize default achievements
(map-set achievement-templates u1 
  {name: "First Break", 
   description: "Take your first mindful break", 
   requirement-type: "total", 
   requirement-value: u1, 
   reward-points: u10})

(map-set achievement-templates u2 
  {name: "Streak Master", 
   description: "Maintain a 7-day break streak", 
   requirement-type: "streak", 
   requirement-value: u7, 
   reward-points: u50})

(map-set achievement-templates u3 
  {name: "Century Club", 
   description: "Take 100 total breaks", 
   requirement-type: "total", 
   requirement-value: u100, 
   reward-points: u100})

(map-set achievement-templates u4 
  {name: "Consistency Champion", 
   description: "Take breaks for 30 consecutive days", 
   requirement-type: "consistency", 
   requirement-value: u30, 
   reward-points: u200})

;; Read-only functions
(define-read-only (get-achievement (achievement-id uint))
  (map-get? achievements achievement-id))

(define-read-only (get-user-achievement (user principal) (achievement-id uint))
  (map-get? user-achievements {user: user, achievement-id: achievement-id}))

(define-read-only (get-user-stats (user principal))
  (default-to 
    {total-points: u0, achievements-count: u0, last-updated: u0}
    (map-get? user-stats user)))

(define-read-only (has-achievement (user principal) (achievement-id uint))
  (is-some (map-get? user-achievements {user: user, achievement-id: achievement-id})))

(define-read-only (get-leaderboard-position (user principal))
  ;; Simplified version - in production would need more complex ranking
  (let ((user-points (get total-points (get-user-stats user))))
    user-points))

;; Public functions
(define-public (create-achievement 
  (name (string-ascii 50))
  (description (string-ascii 200))
  (requirement-type (string-ascii 20))
  (requirement-value uint)
  (reward-points uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (let ((achievement-id (var-get next-achievement-id))
          (current-height burn-block-height))
      (map-set achievements
        achievement-id
        {name: name,
         description: description,
         requirement-type: requirement-type,
         requirement-value: requirement-value,
         reward-points: reward-points,
         created-at: current-height})
      (var-set next-achievement-id (+ achievement-id u1))
      (ok achievement-id))))

(define-public (award-achievement (user principal) (achievement-id uint))
  (let ((achievement (unwrap! (map-get? achievements achievement-id) ERR-ACHIEVEMENT-NOT-FOUND))
        (current-height burn-block-height))
    (asserts! (not (has-achievement user achievement-id)) ERR-ALREADY-EARNED)
    
    ;; Award the achievement
    (map-set user-achievements
      {user: user, achievement-id: achievement-id}
      {earned-at: current-height, points-awarded: (get reward-points achievement)})
    
    ;; Update user stats
    (let ((current-stats (get-user-stats user)))
      (map-set user-stats
        user
        {total-points: (+ (get total-points current-stats) (get reward-points achievement)),
         achievements-count: (+ (get achievements-count current-stats) u1),
         last-updated: current-height}))
    
    (ok {achievement-id: achievement-id, points: (get reward-points achievement)})))

(define-public (check-and-award-achievements (user principal) (streak uint) (total-breaks uint))
  ;; This would be called by the main contract after each break
  (begin
    ;; Check First Break achievement
    (if (and (is-eq total-breaks u1) (not (has-achievement user u1)))
      (begin (unwrap-panic (award-achievement user u1)) true)
      true)
    
    ;; Check Streak Master achievement
    (if (and (>= streak u7) (not (has-achievement user u2)))
      (begin (unwrap-panic (award-achievement user u2)) true)
      true)
    
    ;; Check Century Club achievement
    (if (and (>= total-breaks u100) (not (has-achievement user u3)))
      (begin (unwrap-panic (award-achievement user u3)) true)
      true)
    
    (ok true)))

(define-public (initialize-default-achievements)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (let ((current-height burn-block-height))
      ;; Create achievements from templates
      (unwrap-panic (create-achievement "First Break" "Take your first mindful break" "total" u1 u10))
      (unwrap-panic (create-achievement "Streak Master" "Maintain a 7-day break streak" "streak" u7 u50))
      (unwrap-panic (create-achievement "Century Club" "Take 100 total breaks" "total" u100 u100))
      (unwrap-panic (create-achievement "Consistency Champion" "Take breaks for 30 consecutive days" "consistency" u30 u200))
      (ok true))))

;; Admin functions
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set contract-owner new-owner)
    (ok new-owner)))
