const chime = new Audio('/grill-inn-new-order-chime.wav');
chime.preload = 'auto';

export async function enableOrderSound() {
  chime.currentTime = 0;
  await chime.play();
}

export async function playOrderSound() {
  chime.currentTime = 0;
  await chime.play();
}
