function settlement(date, spent, change, action, assigned = 0, before = 0) {
  const adjusted = 50000 - assigned;
  const leftover = Math.max(0, adjusted - spent);
  const overspent = Math.max(0, spent - adjusted);
  const uncovered = overspent + Math.min(0, change);
  const amountsMinor = {
    baseLimit: 50000, adjustedLimit: adjusted, spent, leftover, overspent,
    walletChange: change, carriedBefore: before, carryAssigned: assigned,
    uncovered, carriedAfter: before - assigned + uncovered,
  };
  return { date, action, ...Object.fromEntries(
    Object.entries(amountsMinor).map(([key, value]) => [key, value / 100])), amountsMinor };
}
module.exports = { settlement };
