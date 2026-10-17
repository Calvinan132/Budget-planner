import app from '../app';
import { runTestSequence } from './testEndpoints';

const PORT = 5000;

const server = app.listen(PORT, async () => {
  console.log(`Server started for test on port ${PORT}`);
  await runTestSequence();
  server.close(() => {
    console.log('Test server closed.');
    process.exit(0);
  });
});
