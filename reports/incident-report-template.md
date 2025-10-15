# Incident Report Template

**Document Control**
- Document ID: INC-TEMPLATE-v2.1
- Created: October 14, 2025
- Last Updated: October 14, 2025
- Owner: SRE Team
- Classification: Internal Use

## Incident Summary

**Incident ID**: [Auto-generated or assigned ID]  
**Date/Time Opened**: [YYYY-MM-DD HH:MM UTC]  
**Date/Time Closed**: [YYYY-MM-DD HH:MM UTC]  
**Duration**: [HH:MM:SS]  
**Severity Level**: [Critical | Major | Minor | Informational]  
**Status**: [Open | In Progress | Resolved | Closed]

### Quick Summary
[One-line description of the incident]

---

## Incident Classification

### Severity Definitions
- **Critical (P1)**: Complete service outage affecting all users
- **Major (P2)**: Significant service degradation affecting >50% users
- **Minor (P3)**: Limited service impact affecting <50% users  
- **Informational (P4)**: No user impact, monitoring/alerting issues

### Impact Assessment
| Metric | Impact Level | Details |
|--------|--------------|---------|
| **Users Affected** | [Number or %] | [Description of user impact] |
| **Services Affected** | [List services] | [Brief description] |
| **Geographic Impact** | [Regions] | [Specific locations affected] |
| **Business Impact** | [High/Med/Low] | [Revenue/SLA/reputation impact] |
| **Data Integrity** | [Affected/Not Affected] | [Any data loss or corruption] |

---

## Timeline of Events

### Detection and Response Timeline
| Time (UTC) | Event | Actions Taken | Owner |
|------------|-------|---------------|-------|
| [HH:MM] | **Incident Detected** | [How was it detected?] | [Name] |
| [HH:MM] | **Initial Response** | [First actions taken] | [Name] |
| [HH:MM] | **Escalation** | [Who was notified?] | [Name] |
| [HH:MM] | **Investigation Started** | [Diagnostic steps] | [Name] |
| [HH:MM] | **Root Cause Identified** | [What was found?] | [Name] |
| [HH:MM] | **Fix Applied** | [Resolution actions] | [Name] |
| [HH:MM] | **Service Restored** | [Verification steps] | [Name] |
| [HH:MM] | **Incident Closed** | [Final verification] | [Name] |

### Detailed Event Log
```
[HH:MM] Event description with relevant context
[HH:MM] Specific actions taken and results
[HH:MM] Communication sent to stakeholders
[Continue chronological order...]
```

---

## Root Cause Analysis

### Problem Description
[Detailed technical description of what went wrong]

### Contributing Factors
1. **Primary Cause**: [Main technical reason]
2. **Secondary Causes**: [Contributing factors]
3. **Environmental Factors**: [External conditions that contributed]

### Technical Details
```yaml
System Components Involved:
- Application: [version, configuration]
- Infrastructure: [servers, networks, databases]
- Dependencies: [external services, APIs]

Error Messages/Logs:
- [Relevant error messages]
- [Stack traces if applicable]
- [Log entries with timestamps]

Metrics at Time of Incident:
- CPU Utilization: [percentage]
- Memory Usage: [percentage]
- Network Traffic: [rates]
- Database Performance: [query times, connections]
- Response Times: [before/during incident]
```

### Why Analysis (5 Whys)
1. **Why did the incident occur?**
   Answer: [First level why]

2. **Why did [first answer] happen?**
   Answer: [Second level why]

3. **Why did [second answer] happen?**
   Answer: [Third level why]

4. **Why did [third answer] happen?**
   Answer: [Fourth level why]

5. **Why did [fourth answer] happen?**
   Answer: [Root cause identified]

---

## Resolution Details

### Immediate Actions Taken
1. **Containment**: [Steps to stop the problem from spreading]
2. **Workaround**: [Temporary fix to restore service]
3. **Communication**: [Notifications sent to users/stakeholders]

### Permanent Fix
```yaml
Resolution Steps:
1. [Detailed step 1]
2. [Detailed step 2]
3. [Detailed step 3]

Configuration Changes:
- [File/system modified]
- [Parameter changes]
- [New settings applied]

Code Changes:
- Repository: [repo name]
- Branch: [branch name]
- Commit: [commit hash]
- Pull Request: [PR number]

Infrastructure Changes:
- [Server modifications]
- [Network changes]
- [Database updates]
```

### Verification
- [ ] Service functionality restored
- [ ] Performance metrics back to normal
- [ ] No related errors in logs
- [ ] User-facing functionality tested
- [ ] Monitoring alerts cleared
- [ ] Stakeholders notified of resolution

---

## Impact Analysis

### Service Level Impact
| SLA Metric | Target | Actual During Incident | Impact |
|------------|---------|------------------------|---------|
| **Availability** | 99.9% | [Actual %] | [Impact description] |
| **Response Time** | <500ms | [Actual time] | [Impact description] |
| **Error Rate** | <0.1% | [Actual rate] | [Impact description] |
| **Throughput** | [Target RPS] | [Actual RPS] | [Impact description] |

### Business Impact
```yaml
Financial Impact:
- Revenue Loss: $[amount] (estimated)
- SLA Credits: $[amount]
- Operational Costs: $[amount]

User Experience Impact:
- Customer Complaints: [number]
- Support Tickets: [number]
- Social Media Mentions: [number]
- User Retention Impact: [analysis]

Reputation Impact:
- Media Coverage: [description]
- Customer Trust: [assessment]
- Competitive Impact: [analysis]
```

### Performance Metrics
```yaml
Before Incident (Baseline):
- Average Response Time: [time]
- Error Rate: [percentage]
- Throughput: [requests/second]
- CPU Utilization: [percentage]

During Incident:
- Peak Response Time: [time]
- Peak Error Rate: [percentage]
- Minimum Throughput: [requests/second]
- Peak CPU Utilization: [percentage]

After Resolution:
- Response Time: [time]
- Error Rate: [percentage]
- Throughput: [requests/second]
- CPU Utilization: [percentage]
```

---

## Communication and Notifications

### Internal Communications
| Time (UTC) | Audience | Channel | Message |
|------------|----------|---------|---------|
| [HH:MM] | On-call Engineer | PagerDuty | Initial alert |
| [HH:MM] | SRE Team | Slack #incidents | Incident declared |
| [HH:MM] | Engineering Leads | Email + Slack | Impact assessment |
| [HH:MM] | Management | Email | Executive briefing |

### External Communications
| Time (UTC) | Audience | Channel | Message |
|------------|----------|---------|---------|
| [HH:MM] | All Users | Status Page | Service degradation notice |
| [HH:MM] | Premium Users | Email | Direct notification |
| [HH:MM] | Partners/APIs | API Notification | Integration impact notice |
| [HH:MM] | All Users | Status Page | Resolution notification |

### Communication Templates Used
- [ ] Initial incident notification
- [ ] Update during investigation
- [ ] Resolution notification
- [ ] Post-incident summary

---

## Lessons Learned

### What Went Well
1. **Detection**: [Positive aspects of how incident was detected]
2. **Response**: [Effective response actions]
3. **Communication**: [Good communication practices]
4. **Tools/Processes**: [Helpful tools or procedures]

### What Could Be Improved
1. **Prevention**: [How could this have been prevented?]
2. **Detection**: [How could we have detected it sooner?]
3. **Response**: [How could response have been faster/better?]
4. **Communication**: [Communication improvements needed]

### Technical Lessons
```yaml
Monitoring Gaps:
- [Alert that should have fired but didn't]
- [Metric that should be monitored]
- [Dashboard that would have helped]

Process Gaps:
- [Procedure that was missing]
- [Documentation that was unclear]
- [Training that would have helped]

Tool Gaps:
- [Tool that would have helped diagnose faster]
- [Automation that could have prevented issue]
- [Integration that was missing]
```

---

## Action Items and Follow-up

### Immediate Actions (Complete within 24 hours)
- [ ] **Action**: [Specific task] **Owner**: [Name] **Due**: [Date]
- [ ] **Action**: [Specific task] **Owner**: [Name] **Due**: [Date]

### Short-term Actions (Complete within 1 week)
- [ ] **Action**: [Specific task] **Owner**: [Name] **Due**: [Date]
- [ ] **Action**: [Specific task] **Owner**: [Name] **Due**: [Date]

### Long-term Actions (Complete within 1 month)
- [ ] **Action**: [Specific task] **Owner**: [Name] **Due**: [Date]
- [ ] **Action**: [Specific task] **Owner**: [Name] **Due**: [Date]

### Process Improvements
- [ ] **Update monitoring**: [Specific monitoring enhancement]
- [ ] **Update documentation**: [Documentation to be updated]
- [ ] **Update procedures**: [Procedure modifications]
- [ ] **Training needed**: [Team training requirements]

### Technical Debt Items
- [ ] **Code improvements**: [Code changes to prevent recurrence]
- [ ] **Infrastructure updates**: [Infrastructure enhancements]
- [ ] **Architecture changes**: [System design improvements]

---

## Prevention Measures

### Monitoring Enhancements
```yaml
New Alerts to be Added:
- Alert Name: [specific alert]
- Threshold: [trigger condition]
- Severity: [alert level]
- Notification: [who gets notified]

Dashboard Updates:
- Dashboard: [name]
- New Metrics: [metrics to add]
- Visualization: [chart types]
```

### Process Improvements
1. **Runbook Updates**: [Specific runbook sections to update]
2. **Automation**: [Tasks that should be automated]
3. **Testing**: [Additional tests to implement]
4. **Documentation**: [Documentation gaps to fill]

### Infrastructure Changes
```yaml
Configuration Updates:
- System: [system name]
- Parameter: [parameter name]
- Old Value: [previous setting]
- New Value: [new setting]
- Reason: [why this change prevents recurrence]

Architecture Improvements:
- Component: [system component]
- Change: [what will be modified]
- Timeline: [when change will be implemented]
- Owner: [responsible team/person]
```

---

## Related Information

### Similar Previous Incidents
| Date | Incident ID | Similarity | Outcome |
|------|-------------|------------|---------|
| [Date] | [ID] | [How similar] | [Resolution] |

### Knowledge Base Articles
- [Link to relevant documentation]
- [Link to troubleshooting guides]
- [Link to architecture documents]

### External References
- [Vendor documentation]
- [Community forums]
- [Best practices guides]

---

## Incident Metrics

### Response Metrics
```yaml
Detection Metrics:
- Time to Detection: [HH:MM:SS]
- Detection Method: [Monitoring/User Report/Other]
- Alert Effectiveness: [Did alerts work as expected?]

Response Metrics:
- Time to Acknowledgment: [HH:MM:SS]
- Time to Engagement: [HH:MM:SS]
- Time to Escalation: [HH:MM:SS]
- Time to Resolution: [HH:MM:SS]

Communication Metrics:
- Time to First Communication: [HH:MM:SS]
- Number of Updates Sent: [count]
- Stakeholder Satisfaction: [survey results if available]
```

### Compliance and Audit
- [ ] Incident logged in required systems
- [ ] Regulatory notifications sent (if applicable)
- [ ] Audit trail preserved
- [ ] Data breach assessment completed (if applicable)
- [ ] Legal review completed (if required)

---

## Sign-off and Approval

### Incident Commander
**Name**: [Name]  
**Date**: [Date]  
**Signature**: [Digital signature]

### Technical Lead
**Name**: [Name]  
**Date**: [Date]  
**Signature**: [Digital signature]

### Service Owner
**Name**: [Name]  
**Date**: [Date]  
**Signature**: [Digital signature]

### Management Approval (for Critical/Major incidents)
**Name**: [Name]  
**Title**: [Title]  
**Date**: [Date]  
**Signature**: [Digital signature]

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | [Date] | [Author] | Initial incident report |
| 1.1 | [Date] | [Author] | Updated with additional details |
| 2.0 | [Date] | [Author] | Root cause analysis completed |
| 2.1 | [Date] | [Author] | Final review and action items |

---

## Appendices

### Appendix A: Log Files and Evidence
[Links to or excerpts from relevant log files, screenshots, metrics, etc.]

### Appendix B: Technical Diagrams
[Network diagrams, architecture diagrams, flow charts relevant to the incident]

### Appendix C: Communication Artifacts
[Copies of status page updates, emails sent, Slack messages, etc.]

### Appendix D: Vendor Communications
[Any communications with external vendors or service providers]

---

*This incident report template should be customized for each incident and all sections should be completed thoroughly. For assistance completing this template, contact the SRE team at sre@company.com.*