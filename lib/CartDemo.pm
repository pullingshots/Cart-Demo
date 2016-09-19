package CartDemo;
use Dancer2;
use Dancer2::Plugin::Cart;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

hook 'plugin.cart.products' => sub {
  my $ec_cart = session('ec_cart');
  $ec_cart->{products} = [ { ec_sku => 'BOOK', ec_price => 100, description => 'The Dancer2 Book' } ];
  session ec_cart => $ec_cart;
};

hook 'plugin.cart.after_checkout' => sub {
  use Dancer2::Plugin::Email;
  my $email = session('ec_cart')->{billing}->{form}->{email};
  email {
    from => 'andrew.baerg@gmail.com',
    to => $email,
    subject => 'Receipt',
    type => 'html',
    body => template 'cart/receipt', { cart => session('ec_cart') }, { layout => 'cart.tt' },
  };
};

true;
