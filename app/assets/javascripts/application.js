document.addEventListener('DOMContentLoaded', function() {
  var video = document.querySelector('video');
  var maxLoop = 3;
  var loop = 0;

  video.onended = function() {
    loop += 1
    if (loop == maxLoop) {
      return;
    }

    setTimeout(function () {
      video.currentTime = 0;
      video.play();
    }, loop * 2500);
  }
  video.play();
  video.playbackRate = 0.75;
});
