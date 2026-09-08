-- Student assignment submissions (Valid / Invalid) from Dalgo / Frappe.
-- Grain: one row per submission (name).
select
  name as submission_id,
  creation,
  assign_id,
  strengths,
  created_at,
  is_primary,
  student_id,
  completed_at,
  encouragement,
  result_status,
  send_feedback,
  submission_url,
  submission_date,
  submission_text,
  submission_type,
  submitted_files,
  overall_feedback,
  student_assignment,
  submission_content,
  submission_validity,
  overall_feedback_translated
from {{ source('dalgo_staging', 'tabSubmission') }}
