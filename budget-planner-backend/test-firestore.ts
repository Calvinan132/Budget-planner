import { db } from './src/config/firebase';
import { PlanService } from './src/services/planService';
import { ReportService } from './src/services/reportService';
import { DailyLogService } from './src/services/dailyLogService';

const TEST_USER = '_test_firebase_flow';

async function listCollections(): Promise<string[]> {
  const cols = await db.listCollections();
  return cols.map((c) => c.id).sort();
}

async function main(): Promise<void> {
  const now = new Date();
  const month = now.getMonth() + 1;
  const year = now.getFullYear();

  try {
    console.log('[TEST] collections BEFORE:', await listCollections());

    // 1. Create a plan through PlanService -> should write to Firestore monthly_plans
    const plan = await PlanService.createPlan(TEST_USER, {
      month,
      year,
      dailyRoutines: [{ name: 'Test breakfast', amount: 20000 }],
      weeklyRoutines: [],
      monthlyFixed: [{ name: 'Test internet', amount: 100000 }],
    });
    console.log('[TEST] PlanService.createPlan OK ->', plan.id);

    // 2. Confirm it actually lives in Firestore
    const planDoc = await db.collection('monthly_plans').doc(plan.id).get();
    console.log('[TEST] monthly_plans doc exists in Firestore =', planDoc.exists);

    // 3. Get it back through getCurrentPlan
    const fetched = await PlanService.getCurrentPlan(TEST_USER, month, year);
    console.log('[TEST] PlanService.getCurrentPlan OK -> totalPlanned =', fetched.totalPlanned);

    // 4. Generate a daily log for today (writes daily_logs)
    const log = await DailyLogService.getTodayLog(TEST_USER);
    console.log('[TEST] DailyLogService.getTodayLog OK -> items =', log.items.length);

    // 5. Read reports from Firestore (new code path)
    const monthly = await ReportService.getMonthlyReport(TEST_USER, month, year);
    console.log('[TEST] ReportService.getMonthlyReport OK ->', JSON.stringify({
      totalPlanned: monthly.totalPlanned,
      actualSpent: monthly.actualSpent,
      skipped: monthly.skippedItemsInsights.length,
    }));

    const history = await ReportService.getDailyHistory(TEST_USER, month, year);
    console.log('[TEST] ReportService.getDailyHistory OK -> daysCount =', history.daysCount);

    console.log('[TEST] collections AFTER:', await listCollections());

    // Cleanup test docs (collections stay as long as >=1 real doc remains)
    await db.collection('monthly_plans').doc(plan.id).delete();
    await db.collection('daily_logs').doc(log.id).delete();
    console.log('[TEST] Cleanup done (test plan + log deleted)');

    console.log('[TEST] RESULT: FULL FLOW OK');
    process.exit(0);
  } catch (err) {
    console.error('[TEST] RESULT: FAILED ->', (err as Error).message);
    console.error(err);
    // best-effort cleanup
    try {
      const planDocId = `${TEST_USER}_${year}_${month.toString().padStart(2, '0')}`;
      await db.collection('monthly_plans').doc(planDocId).delete();
    } catch {}
    process.exit(1);
  }
}

main();
