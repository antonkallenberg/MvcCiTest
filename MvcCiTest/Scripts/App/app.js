;function HomePage() { };
HomePage.prototype.init = function () {
    $("h2").css("color", "red");
};
;(function() {

  this.AboutPage = (function() {

    function AboutPage() {}

    AboutPage.prototype.init = function() {
      return $("h2").css({
        color: 'green'
      });
    };

    return AboutPage;

  })();

}).call(this);

;$(function () {
    var bodyId = $('body').attr('id');
    if (bodyId === "HomePage") {
        var home = new HomePage();
        home.init();
    }else if (bodyId === "AboutPage") {
        var about = new AboutPage();
        about.init();
    }
});
