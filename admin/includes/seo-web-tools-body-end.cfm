<!--- GOOGLE LOGIN ANTIGO SCRIPT --->

<script src="https://apis.google.com/js/platform.js" async defer></script>


<!--- GOOGLE LOGIN ANTIGO --->

<script>

    <cfif NOT isDefined("COOKIE.id")>
        function onSignIn(googleUser) {
            console.log('onSignIn');
            var profile = googleUser.getBasicProfile();
            console.log('ID: ' + profile.getId()); // Do not send to your backend! Use an ID token instead.
            console.log('Name: ' + profile.getName());
            console.log('Image URL: ' + profile.getImageUrl());
            console.log('Email: ' + profile.getEmail()); // This is null if the 'email' scope is not present.
            window.location.href = '/admin/?action=googlesignin&id=' + profile.getId() + '&name=' + profile.getName() + '&email=' + profile.getEmail() + '&imagem_usuario=' + profile.getImageUrl();
        }
    </cfif>

    function signOut() {
        // logoutFacebook();
        var auth2 = gapi.auth2.getAuthInstance();
        auth2.signOut().then(function () {
            console.log('User signed out.');
            window.location.href = '/admin/?action=googlesignout';
        });
    }

</script>


<!--- JQUERY --->

<script src="/assets/js/code.jquery.com_jquery-3.7.1.min.js"></script>


<!--- MDB ESSENTIAL --->

<script type="text/javascript" src="/assets/js/mdb.umd.min.js"></script>


<!--- MDB PLUGINS --->

<script type="text/javascript" src="/assets/plugins/js/all.min.js"></script>
