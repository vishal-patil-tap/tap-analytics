{% macro tlm_excluded_phone_filter(phone_column) %}
{{ phone_column }} not in (
  {%- for phone in var('tlm_excluded_phones') %}
    '{{ phone }}'{% if not loop.last %},{% endif %}
  {%- endfor %}
)
{% endmacro %}


{% macro tlm26_engagement_flow_name(flow_name_column) %}
(
  regexp_contains({{ flow_name_column }}, r'^TLM26_Student_Engagement\d*Flow$')
  or {{ flow_name_column }} like 'TLM26_Student_EngagementFlow'
  or regexp_contains({{ flow_name_column }}, r'^TLM26_Batch2Student_Engagement\d*Flow$')
  or {{ flow_name_column }} like 'TLM26_Batch2Student_EngagementFlow'
)
{% endmacro %}


{% macro is_quiz_attempted_body(body_column) %}
(
  {{ body_column }} like "%Let's try the next question%"
  or {{ body_column }} like "%कोई चिंता नहीं! आइए अगला प्रश्न आज़माएँ%"
  or {{ body_column }} like "%काळजी करू नका! 🤗 पुढचा प्रश्न करून पाहू%"
  or {{ body_column }} like "%ਕੋਈ ਚਿੰਤਾ ਨਹੀਂ! 🤗 ਆਓ ਅਗਲੇ ਸਵਾਲ ਦੀ ਕੋਸ਼ਿਸ਼ ਕਰੀਏ%"
)
{% endmacro %}
