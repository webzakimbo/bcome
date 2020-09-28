module Bcome::Driver::Gcp::Authentication::Utilities

  def oauth_redirect_html
    ## [GR] Style rules: Explicitly no assets to be pulled from bcome remote (no tracking). Inline styles only.
    ## Made an exception for the google font, as the user is already oauthing against google in any case.
    <<-HTML
      <html>
        <head>
          <script>
            function closeWindow() {
              window.open('', '_self', '');
              window.close();
            }
            setTimeout(closeWindow, 10);
          </script>
        </head>
        <style>
          @import url("https://fonts.googleapis.com/css2?family=Catamaran:wght@200;500&display=swap");

          body {
            font-family: 'Catamaran', sans-serif;
            font-weight: 200;
            color: #3E4E60;
          }
        </style>
        <body>#{oauth_redirect_body}</body>
      </html>
    HTML
  end

  def oauth_redirect_body
    <<-HTML
     <p>
       OAuth redirection for namespace <strong>#{@node.keyed_namespace}</strong> complete.
     </p>
     <p>
       You may close this window and return to the Bcome Console.
     </p>
    HTML
  end

end
