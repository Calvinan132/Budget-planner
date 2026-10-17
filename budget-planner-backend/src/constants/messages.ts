export const MESSAGES = {
  USER: {
    SYNC_SUCCESS: 'User profile synced successfully',
    PROFILE_NOT_FOUND: 'User profile not found',
    UNAUTHORIZED: 'Unauthorized: Invalid or missing token',
  },
  PLAN: {
    CREATED_SUCCESS: 'Monthly plan created successfully',
    UPDATED_SUCCESS: 'Monthly plan updated successfully',
    NOT_FOUND: 'No active plan found for the specified month',
    ALREADY_EXISTS: 'Plan already exists for this month',
  },
  DAILY: {
    LOG_RETRIEVED: 'Today daily log retrieved successfully',
    CHECK_IN_SUCCESS: 'Check-in item status updated successfully',
    UNEXPECTED_EXPENSE_SUCCESS: 'Unexpected expense logged successfully',
    ITEM_NOT_FOUND: 'Specified check-in item not found in daily log',
    LOG_NOT_FOUND: 'Daily log not found for today',
  },
  REPORT: {
    MONTHLY_SUCCESS: 'Monthly performance report retrieved successfully',
    HISTORY_SUCCESS: 'Daily breakdown history retrieved successfully',
  },
  SERVER: {
    INTERNAL_ERROR: 'Internal Server Error',
    VALIDATION_ERROR: 'Validation Error',
  },
} as const;
