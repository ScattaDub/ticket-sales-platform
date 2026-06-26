import * as fs from "node:fs";


console.log('start');

setImmediate(() => {
    console.log('setImmediate');
});

setTimeout(() => {
    console.log('setTimeout');
}, 0);

process.nextTick(() => {
  console.log('nextTick');
});

Promise.resolve().then(() => {
  console.log('promise');
});

console.log('end');


// start, end, promise, nextTick, (setTimeout, setImmediate OR setImmediate, setTimeout)

fs.readFile('./db.ts', () => {
    setTimeout(() => {
        console.log('setTimeout');
    }, 0);

    setImmediate(() => {
        console.log('setImmediate');
    });
});

// setImmediate, setTimeout