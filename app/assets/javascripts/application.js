document.addEventListener('DOMContentLoaded', function() {
  if (window.innerWidth <= 768) {
    return ;
  }
  var video = document.querySelector('video');
  var loading = document.querySelector('#video-loading');
  var container = document.querySelector("#header-hero-container");
  var help = document.querySelector("#help-hero-container .hero");
  var overlay = document.querySelector("#overlay-hero");
  var ended = false;

  var maxLoop = 3;
  var loop = 0;

  video.onended = function() {
    loop += 1
    if (loop == maxLoop) {
      ended = true;
      return;
    }

    setTimeout(function () {
      video.currentTime = 0;
      video.play();
    }, loop * 2500);
  }
  video.onplay = function() {
    loading.style.display = "none";
  }
  video.play();
  video.playbackRate = 0.75;

  var lastScroll = 0;
  var ticking = false;
  window.addEventListener('scroll', function(e) {
    lastScroll = window.scrollY;

    if (!ticking) {
      window.requestAnimationFrame(function() {
        ticking = false;
        if (lastScroll > 450) {
          return;
        }
        if (!ended) {
          if (lastScroll < 50) {
            video.play();
          } else {
            video.pause();
          }
        }

        // var newHeight = "calc(78vh - " + lastScroll / 2 + "px)"
        // container.style.maxHeight = newHeight;
        // // video.style.height = newHeight;
        // loading.style.height = newHeight;
        // overlay.style.height = newHeight;

        // help.style.top = "calc(78vh - 450px - " + lastScroll + "px)";
      });
    }

    ticking = true;
  });
});
