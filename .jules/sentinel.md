## 2026-03-30 - Client-side Sensitive Data Exposure and Technical Error Leakage
**Vulnerability:** Client-side JavaScript logged raw AJAX response payloads (`console.log`) and displayed raw server error details (`errorThrown`) directly to users via `apex.message.showErrors`.
**Learning:** Console logging in client-side APEX scripts leaks structured data to browser developer tools, while exposing unhandled error details creates potential technical information leakage vector.
**Prevention:** Remove all debug `console.log` statements from production/demo JS files and replace raw technical error parameters with generic user-friendly messages.
