<script setup>
import { onMounted, ref, computed } from 'vue'
import { RouterLink } from 'vue-router'
import { api } from '../services/api'
// The overview contains dashboard statistics and the report review queue.
const overview = ref(null)
// Store the report currently being updated so only its actions are disabled.
const updating = ref(null)
onMounted(async () => {
  // The backend returns the statistics and reports in one admin-only request.
  overview.value = await api.getAdminOverview()
})

const openReports = computed(() =>
  overview.value?.reports.filter((r) => r.status === 'Open' || r.status === 'In review') || []
)

async function updateStatus(reportId, status) {
  // Prevent duplicate status updates while this specific report is in flight.
  updating.value = reportId
  try {
    overview.value = await api.updateReportStatus(reportId, status)
  } finally {
    updating.value = null
  }
}
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div class="d-flex justify-content-between align-items-end gap-3 mb-4">
        <div>
          <p class="eyebrow">Administrator workspace</p>
          <h1 class="page-title">Content overview.</h1>
          <p class="page-subtitle">
            Review activity and keep the UniMeal community useful and safe.
          </p>
        </div>
        <RouterLink class="btn btn-outline-primary rounded-pill" to="/admin/manage"
          >Manage data</RouterLink
        >
      </div>
      <div v-if="!overview" class="py-5 text-center text-secondary">
        Loading administration data...
      </div>
      <template v-else
        ><div class="row g-4">
          <div v-for="card in overview.statistics" :key="card.label" class="col-sm-6 col-xl-3">
            <article class="surface-card p-4 h-100">
              <p class="stat-label">{{ card.label }}</p>
              <strong class="stat-value">{{ card.value }}</strong>
              <p class="stat-note mb-0">{{ card.note }}</p>
            </article>
          </div>
        </div>
        <section class="surface-card p-4 p-md-5 mt-4">
          <div class="d-flex flex-column flex-md-row justify-content-between gap-2 mb-3">
            <div>
              <h2 class="admin-heading">Reported content</h2>
            </div>
            <span class="text-secondary small">{{ overview.reports.length }} reports</span>
          </div>
          <!-- Preserve table usability on narrow screens with horizontal scrolling. -->
          <div class="table-responsive">
            <table class="table align-middle mb-0">
              <thead>
                <tr>
                  <th>Target</th>
                  <th>Reporter</th>
                  <th>Reason</th>
                  <th>Status</th>
                  <th class="text-end">Review</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="report in openReports" :key="report.id">
                  <td>
                    <!-- The target title is paired with its content type and report date. -->
                    <strong>{{ report.targetTitle }}</strong
                    ><small>{{ report.targetType }} · {{ report.createdAt }}</small>
                  </td>
                  <td>{{ report.reporter }}</td>
                  <td>{{ report.reason }}</td>
                  <td>
                    <span
                      class="status-pill"
                      :class="report.status.toLowerCase().replace(' ', '-')"
                      >{{ report.status }}</span
                    >
                  </td>
                  <td class="text-end">
                    <!-- Moderation actions update the report and refresh the supplied overview. -->
                    <div class="btn-group btn-group-sm">
                      <button
                        class="btn btn-outline-primary"
                        :disabled="updating === report.id"
                        @click="updateStatus(report.id, 'In review')"
                      >
                        Review</button
                      ><button
                        class="btn btn-outline-primary"
                        :disabled="updating === report.id"
                        @click="updateStatus(report.id, 'Resolved')"
                      >
                        Resolve</button
                      ><button
                        class="btn btn-outline-secondary"
                        :disabled="updating === report.id"
                        @click="updateStatus(report.id, 'Dismissed')"
                      >
                        Dismiss
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section></template
      >
    </div>
  </section>
</template>

<style scoped>
/* Small statistic labels establish hierarchy above the dashboard totals. */
.stat-label {
  color: var(--um-muted);
  font-size: 0.86rem;
  font-weight: 700;
}
/* Large values make the four high-level moderation counts easy to scan. */
.stat-value {
  display: block;
  margin: 0.5rem 0;
  color: var(--um-green);
  font-size: 2.35rem;
  letter-spacing: -0.05em;
}
/* The note supplies a concise change or context for each statistic. */
.stat-note {
  color: var(--um-coral);
  font-size: 0.78rem;
  font-weight: 750;
}
/* Section heading for the report-review table. */
.admin-heading {
  color: var(--um-ink);
  font-size: 1.45rem;
  font-weight: 800;
}
/* Uppercase table headers distinguish the column labels from reported content. */
.table th {
  color: var(--um-muted);
  font-size: 0.75rem;
  text-transform: uppercase;
}
.table td {
  padding: 1rem 0.5rem;
  color: var(--um-ink);
}
.table small {
  display: block;
  color: var(--um-muted);
  margin-top: 0.2rem;
}
.status-pill {
  display: inline-block;
  border-radius: 99px;
  padding: 0.32rem 0.55rem;
  font-size: 0.72rem;
  font-weight: 800;
}
.open {
  color: #a85b11;
  background: #fff0d7;
}
.in-review {
  color: #205e87;
  background: #dceef9;
}
.resolved {
  color: var(--um-green);
  background: var(--um-green-light);
}
.dismissed {
  color: #6d706b;
  background: #ecece8;
}
</style>
