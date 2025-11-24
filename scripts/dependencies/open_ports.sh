open_ports() {
  echo
  echo "To handle the SSL certificate we will have to open the port 80 and the port 443"
  echo

  if ! command -v ufw; then
    echo "UFW nos intalled. We are going to install it to allow openning ports 80 and 443 on this machine."
    sudo apt install ufw
  fi

  sudo ufw allow 22
  sudo ufw allow 80
  sudo ufw allow 443
  sudo ufw enable </dev/tty
}

echo "───────────────────────────────────────────────"
echo "Now we are going to open the necessary ports for Decidim to work ussing UFW."
echo
read -p "Can we proceed openning ports 22, 80 and 443? [y/N] " yn </dev/tty

case $yn in
[Yy]*)
  open_ports
  ;;
*)
  echo "Not openning ports."
  exit 1
  ;;
esac

echo "───────────────────────────────────────────────"
