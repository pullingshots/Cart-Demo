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

true;
