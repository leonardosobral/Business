<!DOCTYPE html>
<html lang="pt-br">

<!--- BACKEND --->
<cfinclude template="includes/backend/backend_login.cfm"/>

<head>
    <meta charset="utf-8">
	<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1" />
    <title>RoadRunners Business</title>
    <link rel="canonical" href="https://business.roadrunners.run" />
    <meta name="twitter:title" content="RoadRunners Business" />
    <meta name="twitter:card" content="summary" />
    <meta name="twitter:description" content="RunnerHub é a junção de corredores com conhecimento e própósito para o desenvolvimento inteligente do esporte." />
    <meta name="twitter:image" content="https://business.roadrunners.run/assets/meta_imagem.jpg" />
    <meta name="twitter:site" content="https://business.roadrunners.run" />
    <meta property="og:type" content="website" />
    <meta property="og:title" content="RoadRunners Business" />
    <meta property="og:description" content="RunnerHub é a junção de corredores com conhecimento e própósito para o desenvolvimento inteligente do esporte." />
    <meta property="og:url" content="https://business.roadrunners.run" />
    <meta property="og:image" content="https://business.roadrunners.run/assets/meta_imagem.jpg" />
	<!-- Favicon -->
	<link rel="shortcut icon" href="favicon.ico">
    <meta name="description" content="RunnerHub é a junção de corredores com conhecimento e própósito para o desenvolvimento inteligente do esporte.">
    <meta name="author" content="RoadRunners Business">

	<!-- 1140px Grid styles for IE -->
	<!--[if lte IE 9]><link rel="stylesheet" href="lib/css/ie.css" type="text/css" media="screen" /><![endif]-->

    <!-- CSS concatenated and minified via ant build script-->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css">

    <link rel="stylesheet" href="lib/css/style.css">
    <link rel="stylesheet" href="lib/css/fontello.css">
    <link rel="stylesheet" href="lib/css/fontello-embedded.css">
    <link rel="stylesheet" href="lib/css/fontello-codes.css">
    <link rel="stylesheet" href="lib/css/animation.css">
    <!--[if IE 7]><link rel="stylesheet" href="lib/css/" + font.fontname + "-ie7.css"><![endif]-->
    <!-- end CSS -->

    <!-- begin Google Fonts -->
    <link href='https://fonts.googleapis.com/css?family=Roboto:400,500,300italic,700,900,400italic,300,500italic' rel='stylesheet' type='text/css'>
    <!-- end Google Fonts -->

    <script src="lib/js/jquery-1.11.1.min.js"></script>
    <script src="lib/js/jquery-migrate-1.2.1.js"></script>

    <script src="https://accounts.google.com/gsi/client" async></script>

    <!--- GOOGLE LOGIN --->

    <script src="https://apis.google.com/js/platform.js" async defer></script>

</head>

<body>

    <!--begin container -->
    <div id="container">

        <!--begin header_wrapper -->
        <header id="header_wrapper">

            <!--begin header -->
            <div id="header" class="clearfix">

                <!--begin logo -->
                <a href="#home" id="logo"><img src="/lib/images/logo2.png" alt="logo"></a>
                <!--end logo -->

                <!--begin nav -->
                <nav id="navigation" role="navigation">
                    <ul id="nav">
<!--                        <li class="selected">-->
<!--                            <a href="./">RunnerHub</a>-->
<!--                        </li>-->
                        <li>
                            <a href="https://roadrunners.run/" target="_blank"><img src="/lib/images/rr.png"></a>
                        </li>
                        <li>
                            <a href="https://openresults.run/" target="_blank"><img src="/lib/images/or.png"></a>
                        </li>
                        <li>
                            <a href="https://runnerhub.run/bi" target="_blank"><img src="/lib/images/rbi.png"></a>
                        </li>
                    </ul>
                </nav>
                <!--end nav -->

            </div>
            <!--end header -->

        </header>
        <!--end header_wrapper -->

        <!--begin home section -->
        <section id="home" class="home_bi">

            <!--begin home_box -->
            <div class="home_box">

                <!--begin home_social_info -->
                <div class="home_social_info">

                    <!--begin home_logo -->
                    <img src="lib/images/logo.png" alt="Logo" class="">
                    <!--end home_logo -->

                    <!--begin social icons -->
                    <ul class="social_icons">
                        <li>
                            <a href="https://www.linkedin.com/company/runnerhub/" target="_blank">
                                <i class="icon icon-linkedin"></i>
                            </a>
                        </li>
                        <li>
                            <a href="https://whatsapp.com/channel/0029VaAE7vc2975GuUCHIK0K" target="_blank">
                                <i class="icon icon-whatsapp"></i>
                            </a>
                        </li>
                    </ul>
                    <!--end social icons -->

                </div>
                <!--end home_social_info -->

                <!--begin row -->
                <div class="row">

                    <!--begin sevencol -->
                    <div class="sevencol">

                    <!---<h2 class="home_title">Running Business Intelligence</h2>--->
                    <img src="/lib/images/runpro.svg" class="w-75">
                    <h3 class="home_subtitle">Toda a tecnologia do RunnerHub<br>a serviço do seu evento.</h3>
                    <!--- <a href="#" class="button_green">Faça parte</a> --->
                        <!---<a href="https://roadrunners.run/" target="_blank" class="button_white" style="padding: 8px"><img src="lib/images/rr.png" style="max-height: 32px"></a>--->
                        <!---<a href="https://openresults.run/" target="_blank" class="button_white" style="padding: 8px"><img src="lib/images/or.png" style="max-height: 32px"></a>--->
                        <a href="#saibamais" class="button_green"><i class="icon icon-info-circled"></i> Saiba mais</a>

                    </div>
                    <!--end sevencol -->

                    <!--begin fivecol -->
                    <div class="fivecol last">

                        <!--begin register_form_wrapper -->
                        <div class="register_form_wrapper">

                            <!--begin register_form -->
                            <div class="register_form">

                                <h3 class="white">Você é um organizador?<br><span class="bold green">Registre-se</span> agora mesmo e solicite o seu <span class="green bold">acesso gratuito</span>.</h3>

                                <div class="row align_center">
<!--                                    <a href="#" class="button_green"><i class="icon icon-google"></i> REGISTRE-SE AGORA</a>-->

                                    <!--- GOOGLE LOGIN NOVO --->

                                    <div id="g_id_onload"
                                        data-client_id="921450846888-qa9a1alk06v6i0ao4jbiihdfrn8j7528.apps.googleusercontent.com"
                                        data-callback="handleCredentialResponse"
                                        data-auto_select="true"
                                        data-auto_prompt="false">
                                    </div>

                                    <div class="g_id_signin"
                                        data-type="standard"
                                        data-size="large"
                                        data-theme="outline"
                                        data-text="sign_in_with"
                                        data-shape="rectangular"
                                        data-logo_alignment="left">
                                    </div>

                                </div>

                                <!--begin success message -->
<!--                                <p class="register_success_box" style="display:none;">Obrigado!</p>-->
                                <!--end success message -->

                                <!--begin register form -->
<!--                                <form id="register-form" class="register" action="register" method="post">-->
                                    <!---
                                    <input class="register-input white-input" type="text" required name="register_names" placeholder="Nome completo" />
                                    <input class="register-input white-input" type="email" required name="register_email" placeholder="Email" />
                                    <input class="register-input white-input" type="text" required name="register_phone" placeholder="Celular" />
                                    --->
<!--                                    <input type="submit" value="REGISTRE-SE GRATUITAMENTE" id="register-button" class="register-submit row" />-->
<!--                                </form>-->
                                <!--end register form -->

                            </div>
                            <!--end register_form -->

                        </div>
                        <!--end register_form_wrapper -->

                    </div>
                    <!--end fivecol -->

                </div>
                <!--end row -->

            </div>
            <!--end home_box -->

        </section>
        <!--end home section -->

        <!--begin section_wrapper -->
        <section class="section_wrapper" id="saibamais">

            <!--begin section_box -->
            <div class="section_box">

                <!--begin row -->
                <div class="row">

                    <!--begin twelvecol -->
                    <div class="twelvecol align_center">

                        <h2 class="title">Transforme dados em sucesso!</h2>
                        <div class="separator_wrapper">
                            <div class="separator_first_circle">
                                <div class="separator_second_circle">
                                </div>
                            </div>
                        </div>
                        <h3 class="subtitle">Planeje, analise e conquiste com o BI do RunnerHub.</h3>

                    </div>
                    <!--end twelvecol -->

                    <!--begin fourcol -->
                    <div class="fourcol home_services">
                        <span class="circle_icons"><i class="icon icon-arrows-cw"></i></span>
                        <h4>Análise de Participação e Desempenho</h4>
                        <p>Permite aos organizadores visualizar e analisar o número de participantes e os tempos médios de conclusão das corridas, identificando tendências e áreas para melhoria.</p>
                    </div>
                    <!--end fourcol -->

                    <!--begin fourcol -->
                    <div class="fourcol home_services">
                        <span class="circle_icons"><i class="icon icon-target"></i></span>
                        <h4>Perfil Demográfico do Público</h4>
                        <p>Fornece uma análise detalhada do perfil dos participantes, incluindo dados demográficos como idade, gênero e localização, ajudando a direcionar campanhas de marketing e comunicação de forma mais eficaz.</p>
                    </div>
                    <!--end fourcol -->

                    <!--begin fourcol -->
                    <div class="fourcol home_services last">
                        <span class="circle_icons"><i class="icon icon-chart-bar"></i></span>
                        <h4>Monitoramento de Engajamento e Retenção</h4>
                        <p>Acompanha o nível de engajamento dos participantes e a taxa de retorno em eventos subsequentes, ajudando os organizadores a entender e aumentar a fidelidade dos corredores.</p>
                    </div>
                    <!--end fourcol -->

                </div>
                <!--end row -->

                <!--begin row -->
                <div class="row align_center">

                    <!--begin twelvecol -->
                    <div class="twelvecol">

                        <a href="#" class="button_green big_button big_top_margin"><i class="icon icon-google"></i> REGISTRE-SE AGORA</a>

                    </div>
                    <!--end twelvecol -->

                </div>
                <!--end row -->

            </div>
            <!--end section_box -->

        </section>
        <!--end section_wrapper -->

        <!--begin section_wrapper -->
        <section class="section_wrapper grey_bg" id="infos">

            <!--begin section_box -->
            <div class="section_box">

                <!--begin row -->
                <div class="row">

                    <!--begin sixcol -->
                    <div class="sixcol">

                        <img src="lib/images/apple.png" alt="screen">

                    </div>
                    <!--end sixcol -->

                    <!--begin sixcol -->
                    <div class="sixcol last">

                        <h3>O que o Run Pro oferece?</h3>

                        <p>O Run Pro é uma poderosa solução que conta com o Business Intelligence do RunnerHub, destinado a organizadores de eventos de corrida de rua. Ele fornece uma análise detalhada dos resultados de edições anteriores, oferecendo insights valiosos sobre o número de participantes, tempos médios de conclusão, e perfil demográfico dos corredores. Essa ferramenta permite aos organizadores planejar estrategicamente futuros eventos, criar campanhas de marketing mais eficazes e melhorar a experiência dos participantes, garantindo maior engajamento e sucesso das corridas.</p>

                        <!--begin featured_dropcap -->
                        <div class="featured_dropcap">
                            <p><b>Organizadores de Eventos de Corrida:</b> Para planejar e otimizar futuros eventos com base em dados históricos. Para analisar a participação e o desempenho dos corredores, melhorando a logística e a organização.</p>
                        </div>
                        <!--end featured_dropcap -->

                        <!--begin featured_dropcap -->
                        <div class="featured_dropcap">
                            <p><b>Agências de Marketing Esportivo:</b> Para criar campanhas de marketing direcionadas e mais eficazes, utilizando dados demográficos e de engajamento dos participantes.</p>
                        </div>
                        <!--end featured_dropcap -->

                        <!--begin featured_dropcap -->
                        <div class="featured_dropcap">
                            <p><b>Empresas Patrocinadoras:</b> Para avaliar o retorno sobre investimento (ROI) em eventos esportivos e decidir sobre futuros patrocínios com base em dados de público e participação.</p>
                        </div>
                        <!--end featured_dropcap -->

                        <!--begin featured_dropcap -->
                        <div class="featured_dropcap">
                            <p><b>Clubes e Assessorias de Corrida:</b> Para entender melhor o perfil de seus atletas e membros, oferecendo treinamentos e eventos personalizados.</p>
                        </div>
                        <!--end featured_dropcap -->

                        <!--begin featured_dropcap -->
                        <div class="featured_dropcap">
                            <p><b>Analistas de Dados Esportivos:</b> Para realizar estudos e gerar relatórios detalhados sobre tendências e padrões em eventos de corrida, ajudando a melhorar estratégias e tomar decisões informadas.</p>
                        </div>
                        <!--end featured_dropcap -->

                    </div>
                    <!--end sixcol -->

                </div>
                <!--end row -->

            </div>
            <!--end section_box -->

        </section>
        <!--end section_wrapper -->

        <!--begin section_wrapper -->
        <section class="section_wrapper" id="sobre">

            <!--begin section_box -->
            <div class="section_box">

                <!--begin row -->
                <div class="row">

                    <!--begin sixcol -->
                    <div class="sixcol">

                        <h3>Sobre a empresa</h3>

                        <!--begin fourcol -->
                        <div class="fourcol">

                            <img src="lib/images/logo2.png" alt="logo RunnerHub" class="img_rounded" style="margin-top: 6px">

                        </div>
                        <!--end fourcol -->

                        <!--begin eightcol -->
                        <div class="eightcol last">

                            <p class="small_margins">Somos a junção de corredores com conhecimento e própósito para o desenvolvimento inteligente do esporte.</p>

                        </div>
                        <!--end eightcol -->

                        <p>
                            O RunnerHub é uma startup brasileira de tecnologia que está revolucionando o mundo do esporte através da corrida de rua. Com uma abordagem centrada no usuário, o RunnerHub integra uma série de ferramentas online, incluindo o calendário online de corridas Road Runners e a plataforma de resultados de corridas Open Results. Essas ferramentas são projetadas para atender às demandas do mercado esportivo, fornecendo soluções personalizadas para atletas, profissionais do esporte e empresas do segmento. Comprometido em usar a tecnologia para unir a comunidade de corrida de rua e ajudar a moldar o futuro do esporte.
                        </p>

                    </div>
                    <!--end sixcol -->

                    <!--begin sixcol -->
                    <div class="sixcol last">

                        <h3>Principais ferramentas</h3>

                        <!--begin testimonials_item -->
                        <div class="testimonials_item">

                            <!--begin fourcol -->
                            <div class="fourcol">
                                <img src="lib/images/rr.png" alt="Image" class="">
                            </div>
                            <!--end fourcol -->

                            <!--begin eightcol -->
                            <div class="eightcol last">

                                <p>Road Runners é muito mais que um calendário de corridas, é uma ferramenta para promoção e planejamento de eventos esportivos, com funcionalidades e integrações exclusivas.</p>
                                <hr>
<!--                                <a href="#" class="button_grey"><i class="icon icon-mail-forward"></i>&nbsp; Acesse agora</a>     -->
                            </div>
                            <!--end eightcol -->

                        </div>
                        <!--end testimonials_item -->

                        <!--begin testimonials_item -->
                        <div class="testimonials_item">

                            <!--begin fourcol -->
                            <div class="fourcol">
                                <img src="lib/images/or.png" alt="Image" class="">
                            </div>
                            <!--end fourcol -->

                            <!--begin eightcol -->
                            <div class="eightcol last">

                                <p>
                                    Open Results é o primeiro portal de resultados de corridas do Brasil, unificando informações em conformidade com as normas da Confederação Brasileira de Atletismo (CBAt), com foco na democratização da informação, tornando a modalidade mais acessível e transparente.
                                </p>
                                <hr>
                                <!--                                <a href="#" class="button_grey"><i class="icon icon-mail-forward"></i>&nbsp; Acesse agora</a>     -->
                            </div>
                            <!--end eightcol -->

                        </div>
                        <!--end testimonials_item -->

                        <!--begin testimonials_item -->
                        <div class="testimonials_item">

                            <!--begin fourcol -->
                            <div class="fourcol">
                                <img src="lib/images/rbi.png" alt="Image" class="">
                            </div>
                            <!--end fourcol -->

                            <!--begin eightcol -->
                            <div class="eightcol last">

                                <p>
                                    O Run BI é a ferramenta de Business Intelligence (BI) do RunnerHub, destinada a organizadores e promotores de eventos de corrida de rua.
                                </p>

                                <!--                                <a href="#" class="button_grey"><i class="icon icon-mail-forward"></i>&nbsp; Acesse agora</a>     -->
                            </div>
                            <!--end eightcol -->

                        </div>
                        <!--end testimonials_item -->

                    </div>
                    <!--end sixcol -->

                </div>
                <!--end row -->

            </div>
            <!--end section_box -->

            <!--begin section_box -->
<!--            <div class="section_box partners_margins">-->
<!--              -->
<!--                &lt;!&ndash;begin row &ndash;&gt;-->
<!--                <div class="row">-->
<!--                    <ul class="partners">-->
<!--                        <li class="first"><img src="http://placehold.it/125x100" alt="Logo"></li>-->
<!--                        <li><img src="http://placehold.it/125x100" alt="Logo"></li>-->
<!--                        <li><img src="http://placehold.it/125x100" alt="Logo"></li>-->
<!--                        <li><img src="http://placehold.it/125x100" alt="Logo"></li>-->
<!--                        <li><img src="http://placehold.it/125x100" alt="Logo"></li>-->
<!--                        <li class="last"><img src="http://placehold.it/125x100" alt="Logo"></li>-->
<!--                    </ul>-->
<!--                </div>-->
<!--                &lt;!&ndash;end row &ndash;&gt;-->
<!--                -->
<!--            </div>-->
            <!--end section_box -->

        </section>
        <!--end section_wrapper -->

        <!--begin section_wrapper -->
        <section class="section_wrapper grey_bg" id="cadastro">

            <!--begin section_box -->
            <div class="section_box align_center">

                <h2>Faça parte agora mesmo!</h2>

                <p>Tenha seu acesso gratuito a tudo o que você sempre buscou no mundo da corrida.</p>

                <!--begin newsletter_wrapper -->
                <div class="newsletter_wrapper">

                    <!--begin success_box -->
<!--                    <p class="newsletter_success_box" style="display:none;">Obrigado!</p>-->
                    <!--end success_box -->

                    <!--begin newsletter-form -->
                    <a href="#" class="button_green"><i class="icon icon-google"></i> REGISTRE-SE AGORA</a>

<!--                    <a href="https://whatsapp.com/channel/0029VaAE7vc2975GuUCHIK0K" target="_blank" class="button_green"><i class="icon icon-whatsapp"></i> Assine agora!</a>-->
<!--                    <form id="newsletter-form" class="newsletter_form" action="newsletter" method="post">
                        <input id="email_newsletter" type="email" name="nf_email" placeholder="Seu email" />
                        <input type="submit" value="Assinar!" id="submit-button-newsletter" />
                    </form>
                    -->
                    <!--end newsletter-form -->

                </div>
                <!--end newsletter_wrapper -->

            </div>
            <!--end section_box -->

        </section>
        <!--end section_wrapper -->

        <!--begin footer -->
        <footer id="footer">

            <!--begin footer_box -->
            <div id="footer_box">

                <!--begin row -->
                <div class="row">

                    <!--begin twelvecol -->
                    <div class="twelvecol">

                        <!--begin footer_social -->
                        <ul class="footer_social">
                            <!---li>
                                <a href="#">
                                    <i class="icon icon-facebook"></i>
                                </a>
                            </li!--->
                            <li>
                                <a href="https://www.instagram.com/runnerhub.run/" target="_blank">
                                    <i class="icon icon-instagram"></i>
                                </a>
                            </li>
                            <li>
                                <a href="https://www.linkedin.com/company/runnerhub/" target="_blank">
                                    <i class="icon icon-linkedin"></i>
                                </a>
                            </li>
                            <li>
                                <a href="https://www.strava.com/clubs/runnerhub" target="_blank">
                                    <i class="icon icon-strava"></i>
                                </a>
                            </li>
                            <li>
                                <a href="https://www.facebook.com/runnerhub.run" target="_blank">
                                    <i class="icon icon-facebook"></i>
                                </a>
                            </li>
                            <li>
                                <a href="https://whatsapp.com/channel/0029VaAE7vc2975GuUCHIK0K" target="_blank">
                                    <i class="icon icon-whatsapp"></i>
                                </a>
                            </li>
                        </ul>
                        <!--end footer_social -->

                        <!--begin copyright -->
                        <div class="copyright ">
                            <p>Copyright © RunnerHub 2023-2025</p>

                        </div>
                        <!--end copyright -->

                    </div>
                    <!--end twelvecol -->

                </div>
                <!--end row -->

            </div>
            <!--end footer_box -->

        </footer>
        <!--end footer -->

        <a href="https://wa.me/5548991534589"
           style="position: fixed;
            width: 52px;
            height: 52px;
            bottom: 20px;
            right: 20px;
            background-color: #25d366;
            color: #FFF;
            border-radius: 50px;
            text-align: center;
            font-size: 36px;
            box-shadow: 1px 1px 2px #888;
            z-index: 1000;" target="_blank">
            <i style="margin-top:8px" class="fa fa-whatsapp"></i>
        </a>

    </div>
    <!--! end of #container -->

    <!-- scripts concatenated and minified via ant build script-->
    <script src="lib/js/modernizr-2.6.1.min.js"></script>
    <script src="lib/js/conditional.js"></script>
    <script src="lib/js/plugins.js"></script>
    <script src="lib/js/jquery.inview.js"></script>
    <script src="lib/js/retina.js"></script>
    <script src="lib/js/bp-script.js"></script>

    <!-- begin jquery.sticky script-->
    <script type="text/javascript" src="lib/js/jquery.sticky.js"></script>
		<script>
        $(window).load(function(){
          $("#header_wrapper").sticky({ topSpacing: 0 });
        });
    </script>
    <!-- end jquery.sticky script-->

    <!-- begin scrollTo script-->
    <script src="lib/js/jquery.scrollTo-min.js"></script>
    <script type="text/javascript">
		(function($){
			$(document).ready(function() {
			/* This code is executed after the DOM has been completely loaded */

				$("a.scrool").click(function(e){

					var full_url = this.href;
					var parts = full_url.split("#");
					var trgt = parts[1];
					var target_offset = $("#"+trgt).offset();
					var target_top = target_offset.top;

					$('html,body').animate({scrollTop:target_top -0}, 1000);
						return false;

				});

			});
		})(jQuery);
    </script>
	<!-- end menu scrollTo script-->

    <!--begin shrink header script -->
    <script>
	$(function(){
	 var shrinkHeader = 705;
	  $(window).scroll(function() {
		var scroll = getCurrentScroll();
		  if ( scroll >= shrinkHeader ) {
			   $('#header_wrapper').addClass('shrink');
			}
			else {
				$('#header_wrapper').removeClass('shrink');
			}
	  });
	function getCurrentScroll() {
		return window.pageYOffset;
		}
	});
	</script>
    <!--end shrink header script -->

    <!--begin fitvids script -->
    <script src="lib/js/jquery.fitvids.js"></script>
	<script>
		// Basic FitVids Test
		$("#container").fitVids();
    </script>
    <!--end fitvids script -->


    <!--- GOOGLE LOGIN ANTIGO --->

    <script>

        function handleCredentialResponse(response) {
            console.log('Google onSignIn');
            const urlRedirect = encodeURI('https://business.roadrunners.run/');
            window.location.href = 'https://business.roadrunners.run/?action=googlesignin&redirect=' + urlRedirect + '&credential=' + response.credential;
        }

        function signOut() {
            google.accounts.id.disableAutoSelect();
            console.log('User signed out.');
            window.location.href = 'https://business.roadrunners.run/?action=googlesignout';
        }

    </script>

</body>

</html>
