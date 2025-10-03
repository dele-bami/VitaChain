# VitaChain – Decentralized Health Data Sovereignty Protocol

## Overview

VitaChain is a **trustless, privacy-first health metrics management protocol** built on Bitcoin’s Layer 2 via the [Stacks](https://stacks.co) blockchain. It empowers individuals with **sovereignty over their health data** by enabling cryptographically-secure recording, validation, and selective sharing of vital signs such as heart rate, blood pressure, glucose levels, and more.

Unlike centralized health platforms, VitaChain ensures that **users maintain absolute ownership and control** of their health metrics while still benefiting from the **immutability, auditability, and security** of Bitcoin.

---

## Key Features

* **Vital Sign Coverage**: Supports 8 major categories (Heart Rate, Blood Pressure, Glucose, Weight, Temperature, Oxygen Saturation, Respiratory Rate).
* **Validation Engine**: Enforces medically realistic ranges to prevent corrupted or invalid data.
* **Immutable Records**: Every entry is stored on-chain, cryptographically verifiable, and tamper-resistant.
* **Granular Data Sovereignty**: Only the data owner (transaction sender) can record, update, or delete their health data.
* **Audit Trails**: Metadata includes counts and latest measurement timestamps for longitudinal tracking.
* **Selective Sharing**: Secure, recipient-based data sharing primitives enable controlled access without giving up sovereignty.

---

## System Architecture

### High-Level Design

VitaChain integrates with the **Stacks blockchain (Proof of Transfer consensus)** to anchor health data to Bitcoin’s security model. The contract is designed to be:

* **User-centric** – All records are tied to the transaction sender (`tx-sender`).
* **Validation-first** – Records undergo strict type and boundary checks.
* **Permission-aware** – Controlled data sharing mechanisms allow for future role-based access extensions.

```
+-------------------------------+
|        VitaChain Users        |
|   (Individuals & Patients)    |
+-------------------------------+
               |
               v
+-------------------------------+
|    Clarity Smart Contract     |
|  - Vital Records Storage      |
|  - Validation Engine          |
|  - Metadata Tracking          |
|  - Sharing Permissions        |
+-------------------------------+
               |
               v
+-------------------------------+
|   Stacks Blockchain (L2)      |
| Anchored to Bitcoin Security  |
+-------------------------------+
```

---

## Contract Architecture

### Storage Maps

* **`vital-records`**: Primary store of vital signs indexed by `(user, timestamp, vital-type)`.
* **`latest-vital-timestamp`**: Tracks the latest measurement timestamp per vital type per user.
* **`vital-count`**: Maintains total count of measurements per vital type per user.

### Core Functions

#### Validation & Queries

* `check-vital-type-validity` → Confirms if a vital type is supported.
* `check-value-validity` → Confirms if a value is within acceptable physiological ranges.
* `get-vital-record` → Fetches a specific record by `(user, timestamp, type)`.
* `get-latest-vital` → Retrieves the latest measurement for a given user/type.
* `get-vital-count` → Returns number of measurements per type.

#### State-Changing

* `record-vital` → Records a new vital metric (with validation & notes).
* `update-vital` → Updates an existing record (owner-only).
* `delete-vital` → Permanently deletes a record, updating metadata.
* `share-vital-with` → Shares a specific record with a designated recipient.

---

## Data Flow

1. **Record Entry**

   * User submits `record-vital` with parameters (`vital-type`, `value`, `timestamp`, `notes`).
   * Contract validates type, physiological range, and timestamp.
   * Record stored in `vital-records`. Metadata updated in `latest-vital-timestamp` & `vital-count`.

2. **Update / Delete**

   * User invokes `update-vital` or `delete-vital`.
   * Contract enforces ownership (`tx-sender`) and integrity checks.
   * Storage is updated, counts adjusted, and latest timestamp recalculated.

3. **Query & Sharing**

   * Read-only functions enable users or approved recipients to fetch latest or specific metrics.
   * `share-vital-with` provides controlled access for external parties (doctors, researchers, or apps).

---

## Error Codes

* **`u100`** → Not Authorized
* **`u101`** → Invalid Vital Type
* **`u102`** → Invalid Value
* **`u103`** → No Data Found
* **`u104`** → Future Timestamp Not Allowed
* **`u105`** → Invalid Timeframe

---

## Future Roadmap

* **Advanced Access Control**: Role-based sharing permissions (doctors, insurers, research orgs).
* **Zero-Knowledge Proofs**: Privacy-preserving verification of health metrics without raw data exposure.
* **IoT Device Integration**: Direct recording from wearables and health monitors.
* **Aggregated Analytics**: On-chain anomaly detection & trend visualization APIs.

---

## Deployment

* **Network**: Stacks blockchain (testnet & mainnet supported).
* **Language**: [Clarity](https://docs.stacks.co/docs/write-smart-contracts/clarity-overview).
* **Consensus**: Anchored to Bitcoin via Proof of Transfer.

---

## License

MIT License – Open for use, extension, and integration in decentralized health applications.
