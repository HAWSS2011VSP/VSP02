## Starten des Systems

Es sind mindestens 3 Erlang Nodes erforderlich.

  Nameservice:

    erl -name ... -setcookie ...
    
    nameservice:start().

  Koordinator:

  Konfiguration in der Datei koordinator.cfg.

    erl -name ... -setcookie ...
    
    coordinator:start().

  Starter:

  Konfiguration in der Datei ggt.cfg.

    erl -name ... -setcookie ...
    
    starter:start(ID).

  Die ID entspricht der Nummer des Starters, damit bei mehreren Startern
  auf einem System eine Identifikation möglich bleibt.
