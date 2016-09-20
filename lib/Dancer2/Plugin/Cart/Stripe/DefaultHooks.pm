hook 'plugin.cart.products' => sub {
  get_stripe_plans;
};
hook 'plugin.cart.after_cart' => sub {
  get_stripe_total
};
hook 'plugin.cart.checkout' => sub {
  charge_stripe
};
true;
