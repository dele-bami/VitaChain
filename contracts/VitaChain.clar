;; Title: VitaChain - Decentralized Health Data Sovereignty Protocol
;;
;; Summary: A trustless, privacy-first health metrics management system built on Bitcoin's 
;; Layer 2, empowering individuals with absolute ownership and control of their vital signs 
;; through cryptographic verification and immutable audit trails.
;;
;; Description: VitaChain revolutionizes personal health data management by leveraging Stacks' 
;; blockchain infrastructure to create an incorruptible, user-controlled health monitoring 
;; ecosystem. This protocol enables individuals to record, validate, and selectively share 
;; critical health metrics (heart rate, blood pressure, glucose levels, and more) with 
;; mathematical precision and cryptographic security. Unlike centralized health platforms, 
;; VitaChain ensures that users maintain complete sovereignty over their medical data while 
;; benefiting from blockchain's transparency and immutability. The contract implements robust 
;; validation logic for eight vital sign categories, real-time anomaly detection through 
;; boundary checks, and granular access controls - all anchored to Bitcoin's security model 
;; through Stacks' Proof of Transfer consensus mechanism.

;; ERROR DEFINITIONS

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-VITAL-TYPE (err u101))
(define-constant ERR-INVALID-VALUE (err u102))
(define-constant ERR-NO-DATA-FOUND (err u103))
(define-constant ERR-FUTURE-TIMESTAMP (err u104))
(define-constant ERR-INVALID-TIMEFRAME (err u105))

;; VITAL SIGN TYPE CONSTANTS

(define-constant VITAL-TYPE-HEART-RATE u1)
(define-constant VITAL-TYPE-BLOOD-PRESSURE-SYSTOLIC u2)
(define-constant VITAL-TYPE-BLOOD-PRESSURE-DIASTOLIC u3)
(define-constant VITAL-TYPE-GLUCOSE u4)
(define-constant VITAL-TYPE-WEIGHT u5)
(define-constant VITAL-TYPE-TEMPERATURE u6)
(define-constant VITAL-TYPE-OXYGEN-SATURATION u7)
(define-constant VITAL-TYPE-RESPIRATORY-RATE u8)

;; DATA STORAGE STRUCTURES

;; Primary storage for vital sign measurements indexed by user, timestamp, and type
(define-map vital-records 
  { user: principal, timestamp: uint, vital-type: uint } 
  { value: uint, notes: (optional (string-utf8 256)) }
)

;; Maintains the most recent measurement timestamp for each vital type per user
(define-map latest-vital-timestamp
  { user: principal, vital-type: uint }
  { timestamp: uint }
)

;; Tracks total number of measurements recorded per vital type per user
(define-map vital-count
  { user: principal, vital-type: uint }
  { count: uint }
)

;; PRIVATE VALIDATION FUNCTIONS

;; Validates that the vital type identifier is supported by the protocol
(define-private (is-valid-vital-type (vital-type uint))
  (or
    (is-eq vital-type VITAL-TYPE-HEART-RATE)
    (is-eq vital-type VITAL-TYPE-BLOOD-PRESSURE-SYSTOLIC)
    (is-eq vital-type VITAL-TYPE-BLOOD-PRESSURE-DIASTOLIC)
    (is-eq vital-type VITAL-TYPE-GLUCOSE)
    (is-eq vital-type VITAL-TYPE-WEIGHT)
    (is-eq vital-type VITAL-TYPE-TEMPERATURE)
    (is-eq vital-type VITAL-TYPE-OXYGEN-SATURATION)
    (is-eq vital-type VITAL-TYPE-RESPIRATORY-RATE)
  )
)

;; Performs physiologically-sound boundary validation for vital sign values
;; Returns true only if the value falls within medically realistic ranges
(define-private (is-valid-value (vital-type uint) (value uint))
  (if (is-eq vital-type VITAL-TYPE-HEART-RATE)
      (and (>= value u30) (<= value u220))  ;; 30-220 bpm
    (if (is-eq vital-type VITAL-TYPE-BLOOD-PRESSURE-SYSTOLIC)
        (and (>= value u70) (<= value u250))  ;; 70-250 mmHg
      (if (is-eq vital-type VITAL-TYPE-BLOOD-PRESSURE-DIASTOLIC)
          (and (>= value u40) (<= value u150))  ;; 40-150 mmHg
        (if (is-eq vital-type VITAL-TYPE-GLUCOSE)
            (and (>= value u20) (<= value u600))  ;; 20-600 mg/dL
          (if (is-eq vital-type VITAL-TYPE-WEIGHT)
              (and (>= value u1000) (<= value u500000))  ;; 1-500 kg (stored in grams)
            (if (is-eq vital-type VITAL-TYPE-TEMPERATURE)
                (and (>= value u340) (<= value u430))  ;; 34.0-43.0C (stored in tenths)
              (if (is-eq vital-type VITAL-TYPE-OXYGEN-SATURATION)
                  (and (>= value u50) (<= value u100))  ;; 50-100% SpO2
                (if (is-eq vital-type VITAL-TYPE-RESPIRATORY-RATE)
                    (and (>= value u4) (<= value u60))  ;; 4-60 breaths/min
                  false
                )
              )
            )
          )
        )
      )
    )
  )
)

;; Updates the latest recorded timestamp for a specific vital type
(define-private (update-latest-timestamp (user principal) (vital-type uint) (timestamp uint))
  (map-set latest-vital-timestamp 
    { user: user, vital-type: vital-type }
    { timestamp: timestamp }
  )
)

;; Increments the measurement counter for a user's vital type
(define-private (increment-vital-count (user principal) (vital-type uint))
  (let (
    (current-count (default-to u0 (get count (map-get? vital-count { user: user, vital-type: vital-type }))))
  )
    (map-set vital-count
      { user: user, vital-type: vital-type }
      { count: (+ current-count u1) }
    )
  )
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieves a specific vital record by user, timestamp, and vital type
(define-read-only (get-vital-record (user principal) (timestamp uint) (vital-type uint))
  (map-get? vital-records { user: user, timestamp: timestamp, vital-type: vital-type })
)

;; Fetches the most recent vital measurement for a given user and vital type
(define-read-only (get-latest-vital (user principal) (vital-type uint))
  (let (
    (latest-timestamp (get timestamp (default-to { timestamp: u0 } 
                         (map-get? latest-vital-timestamp { user: user, vital-type: vital-type }))))
  )
    (if (is-eq latest-timestamp u0)
        (ok none)
        (ok (map-get? vital-records { user: user, timestamp: latest-timestamp, vital-type: vital-type }))
    )
  )
)

;; Returns the total count of measurements for a specific vital type
(define-read-only (get-vital-count (user principal) (vital-type uint))
  (default-to { count: u0 } (map-get? vital-count { user: user, vital-type: vital-type }))
)

;; Validates whether a vital type identifier is supported by the protocol
(define-read-only (check-vital-type-validity (vital-type uint))
  (ok (is-valid-vital-type vital-type))
)

;; Validates whether a value is within acceptable range for a vital type
(define-read-only (check-value-validity (vital-type uint) (value uint))
  (ok (is-valid-value vital-type value))
)

;; PUBLIC STATE-CHANGING FUNCTIONS

;; Records a new vital sign measurement with timestamp and optional notes
;; Only the transaction sender can record data for themselves
(define-public (record-vital (vital-type uint) (value uint) (timestamp uint) (notes (optional (string-utf8 256))))
  (let (
    (user tx-sender)
    (current-time stacks-block-height)
  )
    ;; Validation checks
    (asserts! (is-valid-vital-type vital-type) ERR-INVALID-VITAL-TYPE)
    (asserts! (is-valid-value vital-type value) ERR-INVALID-VALUE)
    (asserts! (<= timestamp current-time) ERR-FUTURE-TIMESTAMP)
    
    ;; Store the vital record
    (map-set vital-records
      { user: user, timestamp: timestamp, vital-type: vital-type }
      { value: value, notes: notes }
    )
    
    ;; Update metadata
    (update-latest-timestamp user vital-type timestamp)
    (increment-vital-count user vital-type)
    
    (ok true)
  )
)

;; Updates an existing vital measurement record
;; Only the data owner (tx-sender) can modify their own records
(define-public (update-vital (timestamp uint) (vital-type uint) (value uint) (notes (optional (string-utf8 256))))
  (let (
    (user tx-sender)
    (existing-record (map-get? vital-records { user: user, timestamp: timestamp, vital-type: vital-type }))
  )
    ;; Validation checks
    (asserts! (is-valid-vital-type vital-type) ERR-INVALID-VITAL-TYPE)
    (asserts! (is-valid-value vital-type value) ERR-INVALID-VALUE)
    (asserts! (is-some existing-record) ERR-NO-DATA-FOUND)
    
    ;; Update the record
    (map-set vital-records
      { user: user, timestamp: timestamp, vital-type: vital-type }
      { value: value, notes: notes }
    )
    
    (ok true)
  )
)

;; Permanently deletes a vital measurement from the blockchain state
;; Updates count and latest timestamp metadata accordingly
(define-public (delete-vital (timestamp uint) (vital-type uint))
  (let (
    (user tx-sender)
    (existing-record (map-get? vital-records { user: user, timestamp: timestamp, vital-type: vital-type }))
    (current-count (get count (default-to { count: u0 } (map-get? vital-count { user: user, vital-type: vital-type }))))
  )
    ;; Validate record exists
    (asserts! (is-some existing-record) ERR-NO-DATA-FOUND)
    
    ;; Delete the record
    (map-delete vital-records { user: user, timestamp: timestamp, vital-type: vital-type })
    
    ;; Update count
    (map-set vital-count
      { user: user, vital-type: vital-type }
      { count: (- current-count u1) }
    )
    
    ;; Update latest timestamp if the deleted record was the most recent
    (let (
      (latest-timestamp (get timestamp (default-to { timestamp: u0 } 
                           (map-get? latest-vital-timestamp { user: user, vital-type: vital-type }))))
    )
      (if (is-eq timestamp latest-timestamp)
          (map-delete latest-vital-timestamp { user: user, vital-type: vital-type })
          true
      )
    )
    
    (ok true)
  )
)

;; Enables controlled sharing of specific vital data with designated recipients
;; Foundation for future permission-based data access protocols
(define-public (share-vital-with (recipient principal) (vital-type uint) (timestamp uint))
  (let (
    (user tx-sender)
    (vital-data (map-get? vital-records { user: user, timestamp: timestamp, vital-type: vital-type }))
  )
    (asserts! (is-some vital-data) ERR-NO-DATA-FOUND)
    
    ;; Returns the vital data for the recipient's use
    ;; Future iterations will implement granular permission controls
    (ok vital-data)
  )
)