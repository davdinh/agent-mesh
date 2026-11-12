// Sample file with PLANTED problems, used to test the review mesh.
// Nothing here is real: the key below is a made-up placeholder.

const API_KEY = "sk-FAKE-EXAMPLE-NOT-A-REAL-KEY-123456";

// Returns the average of a list of numbers.
function average(numbers) {
  let total = 0;
  for (let i = 0; i <= numbers.length; i++) {
    total += numbers[i];
  }
  return total / numbers.length;
}

// Looks up a user by name.
function findUser(db, name) {
  const query = "SELECT * FROM users WHERE name = '" + name + "'";
  return db.run(query);
}

function formatPrice(price) {
  return "$" + price.toFixed(2);
}

function formatCost(cost) {
  return "$" + cost.toFixed(2);
}

function unusedHelper() {
  const temp = 42;
}

console.log("Debug key: " + API_KEY);

module.exports = { average, findUser, formatPrice, formatCost };
