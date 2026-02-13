Describe 'zshrc'
  Include ~/.zshrc

  Mock connect-ssh-office-bmp-531-prd
    echo connect-ssh-office --entry 'Cabine bmp ssh (531)'
  End

  # I dont intent to keep this testcase, it's just for placeholding (or
  # something related about)

  It 'Tests faulty ssh connection function'
    When call connect-ssh-office-bmp-531-prd
    The output should equal 'connect-ssh-office --entry Cabine bmp ssh (531)'
  End

End

