package Dancer2::Plugin::Cart::Stripe;
use strict;
use warnings;
use Dancer2::Plugin;
use Net::Stripe;

sub BEGIN{
  has 'api_key' => (
    is => 'ro',
    from_config => 1,
    default => sub { '' }
  );
  has 'public_api_key' => (
    is => 'ro',
    from_config => 1,
    default => sub { '' }
  );
  has 'currency' => (
    is => 'ro',
    from_config => 1,
    default => sub { '' }
  );
  plugin_keywords qw/
   get_stripe_plans
   get_stripe_total
   charge_stripe
  /;
}

sub BUILD {
  my $self = shift;
  my $settings = $self->app->config;
}

sub get_stripe_plans {
  my ($self, $params)  = @_;
  return unless $self->api_key;

  $self->dsl->debug("Getting Stripe Plans");
  $self->dsl->debug("using api key ".$self->api_key);

  my $stripe = Net::Stripe->new(api_key => $self->api_key);
  my $plans = $stripe->get_plans();  

  my $ec_cart = $self->app->session->read("ec_cart");

  $ec_cart->{products} = [ map {
    {
      ec_sku => $_->id,
      ec_price => sprintf('%.2f', $_->amount * 0.01),
      description => $_->name,
      stripe_plan => 1,
    }
  } @{ $plans->data } ];

  $self->app->session->write("ec_cart",$ec_cart);
  return $ec_cart->{products};
}

sub get_stripe_total {
  my ($self, $params)  = @_;
  return unless $self->api_key;

  my $ec_cart = $self->app->session->read("ec_cart");
  $ec_cart->{cart}->{stripe_total} = sprintf('%.0f', $ec_cart->{cart}->{total} * 100);
  $self->app->session->write("ec_cart",$ec_cart);

  return $ec_cart->{cart}->{stripe_total};
}

sub charge_stripe {
  my ($self, $params) = @_;
  return unless $self->api_key;

  my $params = { $self->app->request->params };
  my $ec_cart = $self->app->session->read("ec_cart");

  my $stripe = Net::Stripe->new(api_key => $self->api_key);
  my $customer = $stripe->post_customer(
                    email => $params->{stripeEmail},
                    card => $params->{stripeToken},
                  );
  my $charge = $stripe->post_charge(
                    amount => $ec_cart->{cart}->{stripe_total},
                    description => $self->app->settings->{appname} . ' Charge',
                    currency => $self->currency,
                    customer => $customer->id,
                  );
  if (!$charge->failure_message) {
    $ec_cart->{stripe}->{customer} = $customer->id;
    $ec_cart->{stripe}->{charge} = $charge->id;
  }
  else {
    $ec_cart->{checkout}->{error} = $charge->{failure_message};
  }
  $self->app->session->write("ec_cart",$ec_cart);

  return $charge->id;
}

1;
