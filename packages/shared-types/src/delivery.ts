// ============================================================
//  Delivery Event Types — Receipt tracking
// ============================================================

/** Types of delivery events */
export enum DeliveryEventType {
  /** Envelope was delivered to the device */
  Delivered = 'delivered',
  /** Message was read/opened by the user */
  Read = 'read',
  /** Media was played (audio/video) */
  Played = 'played',
}

/** A delivery/receipt event for an envelope */
export interface DeliveryEvent {
  /** UUID primary key */
  id: string;
  /** The envelope this receipt is for */
  envelope_id: string;
  /** The device reporting the event */
  device_id: string;
  /** Type of event */
  event_type: DeliveryEventType;
  /** ISO 8601 */
  created_at: string;
}

/** Payload for submitting a receipt */
export interface SubmitReceipt {
  envelope_id: string;
  event_type: DeliveryEventType;
}
