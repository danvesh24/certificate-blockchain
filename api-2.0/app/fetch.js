const axios = require('axios');

async function fetchData() {
  try {
    // First API call
    const userResponse = await axios.get('http://192.168.1.64:3375/api/v1/users/signup');
    const user = userResponse.data;
    console.log('User Data:', user);

    // // Extract user ID to use as a parameter for the second API call
    // const userId = user.id;

    // // Second API call using userId from the first response
    // const postsResponse = await axios.get(`https://jsonplaceholder.typicode.com/posts`, {
    //   params: { userId } // Pass userId as a query parameter
    // });
    // const posts = postsResponse.data;
    // console.log('Posts by User:', posts);

    // Combine or process data as needed
    return { user };
  } catch (error) {
    console.error('Error fetching data:', error.message);
  }
}

// Execute the function
exports.fetchData = fetchData;
