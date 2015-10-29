


function getUserData(userIds) {
  var data = {}
  for (var id of usersIds) {
    fetch(`/usrs/${id}`).then(resp => resp.json()).then(user => {
      data[id] = user
    })
  }
}


for (var i of [1,2,3]) {
  setTimeout(() => console.log(i), 0)
}

// 3
// 3
// 3

for (let i of [1,2,3]) {
  setTimeout(() => console.log(i), 0)
}

// 1
// 2
// 3


function getUserData(userIds) {
  let data = {}
  for (let id of usersIds) {
    fetch(`/usrs/${id}`).then(resp => resp.json()).then(user => {
      data[id] = user
    })
  }
}


function myfunc(input) {
  if (input > 0) {
    var x = true
  }
  else {
    var x = false
  }
  return x
}
