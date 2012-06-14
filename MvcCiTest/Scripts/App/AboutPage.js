(function() {

  this.AboutPage = (function() {

    AboutPage.name = 'AboutPage';

    function AboutPage() {}

    AboutPage.prototype.init = function() {
      return $("h2").css({
        color: 'green'
      });
    };

    return AboutPage;

  })();

}).call(this);
