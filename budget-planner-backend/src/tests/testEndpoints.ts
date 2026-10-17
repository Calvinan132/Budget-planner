import http from 'http';

const BASE_URL = 'http://localhost:5000/api';

async function makeRequest(method: string, path: string, body?: any) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${BASE_URL}${path}`);
    const options: http.RequestOptions = {
      method,
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      headers: {
        'Content-Type': 'application/json',
        'x-dev-user-id': 'test_user_demo_99',
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

export async function runTestSequence() {
  console.log('🧪 Starting API Verification Test Sequence...\n');

  try {
    // 1. Sync User
    console.log('1️⃣ POST /api/users/sync');
    const syncRes: any = await makeRequest('POST', '/users/sync', {
      email: 'test_user@budgetplanner.com',
      displayName: 'Test User Demo',
      fcmToken: 'fcm_mock_token_12345',
    });
    console.log('Result:', syncRes.status, JSON.stringify(syncRes.body, null, 2));

    // 2. Create Master Plan
    console.log('\n2️⃣ POST /api/plans');
    const planRes: any = await makeRequest('POST', '/plans', {
      month: 9,
      year: 2026,
      dailyRoutines: [
        { name: 'Ăn sáng', amount: 35000 },
        { name: 'Cà phê', amount: 25000 },
      ],
      weeklyRoutines: [
        { name: 'Xem phim cuối tuần', amount: 120000, frequencyPerWeek: 1 },
      ],
      monthlyFixed: [{ name: 'Tiền mạng Internet', amount: 220000 }],
    });
    console.log('Result:', planRes.status, JSON.stringify(planRes.body, null, 2));

    // 3. Get Today Daily Check-in Log
    console.log('\n3️⃣ GET /api/daily/today');
    const todayRes: any = await makeRequest('GET', '/daily/today?date=2026-09-30');
    console.log('Result:', todayRes.status, JSON.stringify(todayRes.body, null, 2));

    const items = todayRes.body?.data?.items || [];
    if (items.length > 0) {
      const firstItemId = items[0].id;

      // 4. Patch Item Status (Skipped)
      console.log(`\n4️⃣ PATCH /api/daily/check-in (Item: ${firstItemId})`);
      const checkInRes: any = await makeRequest('PATCH', '/daily/check-in?date=2026-09-30', {
        itemId: firstItemId,
        status: 'skipped',
      });
      console.log('Result:', checkInRes.status, JSON.stringify(checkInRes.body, null, 2));
    }

    // 5. Post Unexpected Expense
    console.log('\n5️⃣ POST /api/daily/unexpected-expense');
    const unexpectedRes: any = await makeRequest('POST', '/daily/unexpected-expense?date=2026-09-30', {
      amount: 50000,
      reason: 'Sửa xe thủng lốp',
    });
    console.log('Result:', unexpectedRes.status, JSON.stringify(unexpectedRes.body, null, 2));

    // 6. Get Monthly Report
    console.log('\n6️⃣ GET /api/reports/monthly');
    const reportRes: any = await makeRequest('GET', '/reports/monthly?month=9&year=2026');
    console.log('Result:', reportRes.status, JSON.stringify(reportRes.body, null, 2));

    // 7. Get History Timeline
    console.log('\n7️⃣ GET /api/reports/history');
    const historyRes: any = await makeRequest('GET', '/reports/history?month=9&year=2026');
    console.log('Result:', historyRes.status, JSON.stringify(historyRes.body, null, 2));

    console.log('\n✅ Test Sequence Finished!');
  } catch (err) {
    console.error('❌ Test sequence error:', err);
  }
}
