<footer></footer>

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
            window.location.href = '/?action=googlesignin&id=' + profile.getId() + '&name=' + profile.getName() + '&email=' + profile.getEmail() + '&imagem_usuario=' + profile.getImageUrl();
        }
    </cfif>

    function signOut(event) {
        var logoutUrl = '/logout.cfm';
        var didRedirect = false;

        if (event && typeof event.preventDefault === 'function') {
            event.preventDefault();
        }

        function goToLogout() {
            if (didRedirect) {
                return;
            }

            didRedirect = true;
            window.location.href = logoutUrl;
        }

        try {
            if (window.google && google.accounts && google.accounts.id) {
                google.accounts.id.disableAutoSelect();
            }

            if (window.gapi && gapi.auth2 && typeof gapi.auth2.getAuthInstance === 'function') {
                var auth2 = gapi.auth2.getAuthInstance();

                if (auth2 && typeof auth2.signOut === 'function') {
                    var signOutResult = auth2.signOut();

                    if (signOutResult && typeof signOutResult.then === 'function') {
                        window.setTimeout(goToLogout, 800);
                        signOutResult.then(goToLogout, goToLogout);
                        return false;
                    }
                }
            }
        } catch (error) {
            console.warn('Google signOut indisponivel, usando logout local.', error);
        }

        goToLogout();
        return false;
    }

</script>

<!--- MDB --->
<script type="text/javascript" src="/assets/js/mdb.umd.min.js"></script>
<script type="text/javascript" src="/assets/plugins/js/all.min.js"></script>

<!--- Custom scripts --->
<script type="text/javascript" src="/assets/js/script.js"></script>
