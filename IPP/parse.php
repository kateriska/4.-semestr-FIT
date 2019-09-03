<?php
// Autor: Katerina Fortova (xforto00)
// Predmet: IPP
// Ukol: parse.php
// Datum: unor - brezen 2019

/*
 * Funkce zavolana pri chybe 23 - napr. pri zadanem spatnem poctu argumentu, spatnych typu operandu nebo vyrazu neodpovidajici zadnemu spravnemu regularnimu vyrazu
 */
function Err()
{
  ob_end_clean();
  fprintf (STDERR, "Chyba - Zadan spatny pocet argumentu, spatne typy operandu nebo vase instrukce neodpovida zadnemu regularnimu vyrazu!\n");
  exit(23);
}

/*
 * Funkce pro validaci spravnych argumentu instrukce s jednim parametrem
 *
 * @param $instruction     nactena instrukce s parametrem
 * @param $first_arg       prvni a jediny argument instrukce
 */
function paramsValidateOne($instruction, $first_arg)
{
  if ((strcmp("DEFVAR", $instruction[0]) == 0) || (strcmp("POPS", $instruction[0]) == 0))
  {
    if ($first_arg != "var")
    {
      Err();
    }
  }
  else if ((strcmp("CALL", $instruction[0]) == 0) || (strcmp("LABEL", $instruction[0]) == 0) || (strcmp("JUMP", $instruction[0]) == 0))
  {
    if ($first_arg != "label")
    {
      Err();
    }
  }
  else if ((strcmp("PUSHS", $instruction[0]) == 0) || (strcmp("WRITE", $instruction[0]) == 0) || (strcmp("EXIT", $instruction[0]) == 0) || (strcmp("DPRINT", $instruction[0]) == 0))
  {
    if (($first_arg == "type") || ($first_arg == "label"))
    {
      Err();
    }
  }
}

/*
 * Funkce pro validaci spravnych argumentu instrukce s dvema parametry
 *
 * @param $instruction     nactena instrukce s parametrem
 * @param $first_arg       prvni argument instrukce
 * @param $sec_arg         druhy argument instrukce
 */
function paramsValidateTwo($instruction, $first_arg, $sec_arg)
{
  if ((strcmp("MOVE", $instruction[0]) == 0) || (strcmp("NOT", $instruction[0]) == 0) || (strcmp("INT2CHAR", $instruction[0]) == 0) || (strcmp("STRLEN", $instruction[0]) == 0) || (strcmp("TYPE", $instruction[0]) == 0))
  {
    if (($first_arg != "var") || ($sec_arg == "type") || ($sec_arg == "label") )
    {
      Err();
    }
  }
  else if ((strcmp("READ", $instruction[0]) == 0))
  {
    if (($first_arg != "var") || ($sec_arg != "type"))
    {
      Err();
    }
  }
}

/*
 * Funkce pro validaci spravnych argumentu instrukce s tremi parametry
 *
 * @param $instruction     nactena instrukce s parametrem
 * @param $first_arg       prvni argument instrukce
 * @param $sec_arg         druhy argument instrukce
 * @param $th_arg          treti argument instrukce
 */
function paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg)
{
  if ((strcmp("ADD", $instruction[0]) == 0) || (strcmp("SUB", $instruction[0]) == 0) || (strcmp("MUL", $instruction[0]) == 0) || (strcmp("IDIV", $instruction[0]) == 0) )
  {
    if (($first_arg != "var") || ($sec_arg == "type") || ($sec_arg == "label") || ($th_arg == "type") || ($th_arg == "label"))
    {
      Err();
    }
  }
  else if ((strcmp("LT", $instruction[0]) == 0) || (strcmp("GT", $instruction[0]) == 0) || (strcmp("EQ", $instruction[0]) == 0) || (strcmp("AND", $instruction[0]) == 0) || (strcmp("OR", $instruction[0]) == 0))
  {
    if (($first_arg != "var") || ($sec_arg == "type") || ($sec_arg == "label") || ($th_arg == "type") || ($th_arg == "label"))
    {
      Err();
    }
  }
  else if ((strcmp("STRI2INT", $instruction[0]) == 0) || (strcmp("CONCAT", $instruction[0]) == 0) || (strcmp("GETCHAR", $instruction[0]) == 0) || (strcmp("SETCHAR", $instruction[0]) == 0))
  {
    if (($first_arg != "var") || ($sec_arg == "type") || ($sec_arg == "label") || ($th_arg == "type") || ($th_arg == "label"))
    {
      Err();
    }
  }
  else if ((strcmp("JUMPIFEQ", $instruction[0]) == 0) || (strcmp("JUMPIFNEQ", $instruction[0]) == 0))
  {
    if (($first_arg != "label") || ($sec_arg == "type") || ($sec_arg == "label") || ($th_arg == "type") || ($th_arg == "label"))
    {
      Err();
    }
  }
}

/*
 * Funkce, ktera cte radek po radku STDIN, porovna validni hlavicku, odstrani komentare, bile znaky a pracuje s pocitadlem instrukci
 */
function Opening()
{
  ob_start();
  $header = ".IPPCODE19";
  // hlavicka - odfiltrovani komentaru, bilych znaku a porovnani validni hlavicky
  $line_header = fgets(STDIN);
  $line_header = preg_replace('/#.*/','',$line_header); // odstraneni komentaru
  $line_header = preg_replace('/\s+/', '', $line_header); // odtraneni bilych znaku
  $line_header = strtoupper($line_header);

  if (strcmp($line_header, $header) != 0)
  {
    fprintf (STDERR, "Chyba - Chybna nebo chybejici hlavicka IPPcode19!\n");
    exit(21);
  }

  // hlavicka v poradku, tedy inicializovat xml
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<program language=\"IPPcode19\">\n";

  $number_of_instruction = 1; // inicializace counteru na instrukce
  while( $lines_reading = fgets(STDIN)) // cte radky vstupu, odfiltrovani mezer a komentaru, hlavicku uz necte
  {
    $lines_reading = preg_replace('/#.*/','',$lines_reading); // odstraneni komentaru

    if (($lines_reading == "") || ($lines_reading == "\n")) // na radku po odstraneni komentare nic neni, tedy smazeme cely prazdny radek
    {
      continue;
    }

    $lines_reading = preg_replace('/\s+/', ' ', $lines_reading); // odstraneni bilych znaku
    $instruction = array(); // ulozeni kazdeho radku s instrukci do pole
    $instruction = explode( ' ', trim($lines_reading) );
    controlInstruction($instruction, $number_of_instruction);

    $number_of_instruction++; // inkrementace counteru

  }
}

/*
 * Funkce pro validaci opcode a poctu argumentu
 *
 * @param $instruction                 nactena instrukce s parametrem
 * @param $number_of_instruction       poradove cislo instrukce v kodu
 */
function controlInstruction($instruction, $number_of_instruction)
{
  // pole pro opcodes vsech instrukci
  $instruction_names = array("MOVE","CREATEFRAME","PUSHFRAME","POPFRAME","DEFVAR","CALL","RETURN","PUSHS","POPS","ADD","SUB","MUL","IDIV","LT","GT","EQ","AND","OR","NOT","INT2CHAR","STRI2INT","READ","WRITE","CONCAT","STRLEN","GETCHAR","SETCHAR","TYPE","LABEL","JUMP","JUMPIFEQ","JUMPIFNEQ","EXIT","DPRINT","BREAK");
  // rozdeleni instrukci podle poctu argumentu
  $instruction_0arg = array("CREATEFRAME","PUSHFRAME","POPFRAME","RETURN","BREAK");
  $instruction_1arg = array("DEFVAR","CALL","PUSHS","POPS","WRITE","LABEL","JUMP","EXIT","DPRINT");
  $instruction_2arg = array("MOVE","INT2CHAR","READ","STRLEN","TYPE","NOT");
  $instruction_3arg = array("ADD","SUB","MUL","IDIV","LT","GT","EQ","AND","OR","STRI2INT","CONCAT","GETCHAR","SETCHAR","JUMPIFEQ","JUMPIFNEQ");

  if ((in_array((strtoupper($instruction[0])), $instruction_names)) == false)
  {
    ob_end_clean(); // pokud narazim na problem, odstranim vse co uz se vygenerovalo na STDOUT
    fprintf (STDERR, "Chyba - Chybny nebo neznamy operacni kod!\n");
    exit(22);
  }

  // validace poctu operandu
  if ((in_array((strtoupper($instruction[0])), $instruction_0arg)) && (count($instruction) == 1))
  {
    $instruction[0] = strtoupper($instruction[0]);
    echo "    <instruction order=\"{$number_of_instruction}\" opcode=\"{$instruction[0]}\">\n";
  }
  else if ((in_array((strtoupper($instruction[0])), $instruction_1arg)) && (count($instruction) == 2))
  {
    $instruction[0] = strtoupper($instruction[0]);
    echo "    <instruction order=\"{$number_of_instruction}\" opcode=\"{$instruction[0]}\">\n";
    checkType($instruction);
  }
  else if ((in_array((strtoupper($instruction[0])), $instruction_2arg)) && (count($instruction) == 3))
  {
    $instruction[0] = strtoupper($instruction[0]);
    echo "    <instruction order=\"{$number_of_instruction}\" opcode=\"{$instruction[0]}\">\n";
    checkType($instruction);
  }
  else if ((in_array((strtoupper($instruction[0])), $instruction_3arg)) && (count($instruction) == 4))
  {
    $instruction[0] = strtoupper($instruction[0]);
    echo "    <instruction order=\"{$number_of_instruction}\" opcode=\"{$instruction[0]}\">\n";
    checkType($instruction);
  }
  else
  {
    Err();
  }
  echo "    </instruction>\n";

}

/*
 * Funkce pro kontrolu typu int, bool, string, label, type a var
 *
 * @param $instruction                 nactena instrukce s parametrem
 */
function checkType($instruction)
{ // INSTRUKCE S JEDNIM ARGUMENTEM
  if (count($instruction) == 2)
  {
    // kontrola int
    if (preg_match('/^int@.*$/', strtolower($instruction[1])))
    {
      if ((preg_match('/^int@[-+]?\d+$/', ($instruction[1]))))
      {
        $first_arg = "int";
        paramsValidateOne($instruction, $first_arg);
        $instruction[1] = ltrim(($instruction[1]),"int@");
        echo "        <arg1 type=\"int\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    // kontrola bool
    else if (preg_match('/^bool@.*$/', strtolower($instruction[1])))
    {
      if (preg_match('/^bool@true$/', ($instruction[1])))
      {
        $first_arg = "bool_t";
        paramsValidateOne($instruction, $first_arg);
        echo "        <arg1 type=\"bool\">true</arg1>\n";
      }
      else if (preg_match('/^bool@false$/', ($instruction[1])))
      {
        $first_arg = "bool_f";
        paramsValidateOne($instruction, $first_arg);
        echo "        <arg1 type=\"bool\">false</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    // kontrola string
    else if (preg_match('/^string@.*$/', strtolower($instruction[1])))
    {
      if (preg_match('/^^string@(([a-zA-Z\x{0021}\x{0022}\x{0024}-\x{005B}\x{005D}-\x{FFFF}])|(\\\\[0-9][0-9][0-9]))*$/', ($instruction[1])))
      {
        $first_arg = "string";
        paramsValidateOne($instruction, $first_arg);
        $instruction[1] = substr(($instruction[1]),7);
        $instruction[1] = preg_replace('/&/', "&amp;", $instruction[1]);
        $instruction[1] = preg_replace('/</', "&lt;", $instruction[1]);
        $instruction[1] = preg_replace('/>/', "&gt;", $instruction[1]);
        echo "        <arg1 type=\"string\">{$instruction[1]}</arg1>\n";
      }
      else if (preg_match('/^string@[^\u0000-\u007F]+/', ($instruction[1])))
      {
        $first_arg = "string";
        paramsValidateOne($instruction, $first_arg);
        echo "        <arg1 type=\"string\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    // kontrola type
    else if (preg_match('/^(int|bool|string)$/', ($instruction[1])))
    {
      $first_arg = "type";
      paramsValidateOne($instruction, $first_arg);
      echo "        <arg1 type=\"type\">{$instruction[1]}</arg1>\n";
    }
    // kontrola var
    else if ((preg_match('/^(GF|LF|TF)@.*$/', strtoupper($instruction[1]))))
    {
      if (preg_match('/^(GF|LF|TF)@([[:alpha:]]|(_|-|\$|&|\?|!|%|\*))([[:alnum:]]|(_|-|\$|&|\?|!|%|\*))*/', ($instruction[1])))
      {
        $first_arg = "var";
        paramsValidateOne($instruction, $first_arg);
        $instruction[1] = preg_replace('/&/', "&amp;", $instruction[1]);
        $instruction[1] = preg_replace('/</', "&lt;", $instruction[1]);
        $instruction[1] = preg_replace('/>/', "&gt;", $instruction[1]);
        echo "        <arg1 type=\"var\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    // kontrola nil
    else if (preg_match('/^nil@.*$/', strtolower($instruction[1])))
    {
      if (preg_match('/^nil@nil$/', ($instruction[1])))
      {
        $first_arg = "nil";
        paramsValidateOne($instruction, $first_arg);
        $instruction[1] = substr(($instruction[1]),4);
        echo "        <arg1 type=\"nil\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil$/', strtolower($instruction[1])))
    {
      Err();
    }
    // ostatni ...@neco filtrovat jako chybu
    else if (preg_match('/[[:alnum:]]@.*$/', ($instruction[1])))
    {
      Err();
    }
    // kontrola label
    else if (preg_match('/^([[:alpha:]]|(_|-|\$|&|%|\*))((_|-|\$|&|%|\*)|[[:alnum:]])*/', ($instruction[1])))
    {
      $first_arg = "label";
      paramsValidateOne($instruction, $first_arg);
      echo "        <arg1 type=\"label\">{$instruction[1]}</arg1>\n";
    }
    else
    {
      Err();
    }
  }

  else if (count($instruction) == 3)
  { // INSTRUKCE S DVEMA ARGUMENTY
    //////////////////////////////////// prvni argument instrukce /////////////////////////////////////////////////////
    if (preg_match('/^int@.*$/', strtolower($instruction[1])))
    {
      if ((preg_match('/^int@[-+]?\d+$/', ($instruction[1]))))
      {
        $first_arg = "int";
        $instruction[1] = ltrim(($instruction[1]),"int@");
        echo "        <arg1 type=\"int\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^bool@.*$/', strtolower($instruction[1])))
    {
      if (preg_match('/^bool@true$/', ($instruction[1])))
      {
        $first_arg = "bool_t";
        echo "        <arg1 type=\"bool\">true</arg1>\n";
      }
      else if (preg_match('/^bool@false$/', ($instruction[1])))
      {
        $first_arg = "bool_f";
        echo "        <arg1 type=\"bool\">false</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^string@.*$/', strtolower($instruction[1])))
    {
      if (preg_match('/^^string@(([a-zA-Z\x{0021}\x{0022}\x{0024}-\x{005B}\x{005D}-\x{FFFF}])|(\\\\[0-9][0-9][0-9]))*$/', ($instruction[1])))
      {
        $first_arg = "string";
        $instruction[1] = substr(($instruction[1]),7);
        $instruction[1] = preg_replace('/&/', "&amp;", $instruction[1]);
        $instruction[1] = preg_replace('/</', "&lt;", $instruction[1]);
        $instruction[1] = preg_replace('/>/', "&gt;", $instruction[1]);
        echo "        <arg1 type=\"string\">{$instruction[1]}</arg1>\n";
      }
      else if (preg_match('/^string@[^\u0000-\u007F]+/', ($instruction[1])))
      {
        $first_arg = "string";
        echo "        <arg1 type=\"string\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^(int|bool|string)$/', ($instruction[1])))
    {
      $first_arg = "type";
      echo "        <arg1 type=\"type\">{$instruction[1]}</arg1>\n";
    }
    else if ((preg_match('/^(GF|LF|TF)@.*$/', strtoupper($instruction[1]))))
    {
      if (preg_match('/^(GF|LF|TF)@([[:alpha:]]|(_|-|\$|&|\?|!|%|\*))([[:alnum:]]|(_|-|\$|&|\?|!|%|\*))*/', ($instruction[1])))
      {
        $first_arg = "var";
        $instruction[1] = preg_replace('/&/', "&amp;", $instruction[1]);
        $instruction[1] = preg_replace('/</', "&lt;", $instruction[1]);
        $instruction[1] = preg_replace('/>/', "&gt;", $instruction[1]);
        echo "        <arg1 type=\"var\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil@.*$/', strtolower($instruction[1])))
    {
      if (preg_match('/^nil@nil$/', ($instruction[1])))
      {
        $first_arg = "nil";
        $instruction[1] = substr(($instruction[1]),4);
        echo "        <arg1 type=\"nil\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil$/', strtolower($instruction[1])))
    {
      Err();
    }
    else if (preg_match('/[[:alnum:]]@.*$/', ($instruction[1])))
    {
      Err();
    }
    else if (preg_match('/^([[:alpha:]]|(_|-|\$|&|%|\*))((_|-|\$|&|%|\*)|[[:alnum:]])*/', ($instruction[1])))
    {
      $first_arg = "label";
      echo "        <arg1 type=\"label\">{$instruction[1]}</arg1>\n";
    }
    else
    {
      Err();
    }
  //////////////////////////////////// druhy argument instrukce /////////////////////////////////////////////////////
    if (preg_match('/^int@.*$/', strtolower($instruction[2])))
    {
      if ((preg_match('/^int@[-+]?\d+$/', ($instruction[2]))))
      {
        $sec_arg = "int";
        paramsValidateTwo($instruction, $first_arg, $sec_arg);
        $instruction[2] = ltrim(($instruction[2]),"int@");
        echo "        <arg2 type=\"int\">{$instruction[2]}</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^bool@.*$/', strtolower($instruction[2])))
    {
      if (preg_match('/^bool@true$/', ($instruction[2])))
      {
        $sec_arg = "bool_t";
        paramsValidateTwo($instruction, $first_arg, $sec_arg);
        echo "        <arg2 type=\"bool\">true</arg2>\n";
      }
      else if (preg_match('/^bool@false$/', ($instruction[2])))
      {
        $sec_arg = "bool_f";
        paramsValidateTwo($instruction, $first_arg, $sec_arg);
        echo "        <arg2 type=\"bool\">false</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^string@.*$/', strtolower($instruction[2])))
    {
      if (preg_match('/^^string@(([a-zA-Z\x{0021}\x{0022}\x{0024}-\x{005B}\x{005D}-\x{FFFF}])|(\\\\[0-9][0-9][0-9]))*$/', ($instruction[2])))
      {
        $sec_arg = "string";
        paramsValidateTwo($instruction, $first_arg, $sec_arg);
        $instruction[2] = substr(($instruction[2]),7);
        $instruction[2] = preg_replace('/&/', "&amp;", $instruction[2]);
        $instruction[2] = preg_replace('/</', "&lt;", $instruction[2]);
        $instruction[2] = preg_replace('/>/', "&gt;", $instruction[2]);
        echo "        <arg2 type=\"string\">{$instruction[2]}</arg2>\n";
      }
      else if (preg_match('/^string@[^\u0000-\u007F]+/', ($instruction[2])))
      {
        $sec_arg = "string";
        paramsValidateTwo($instruction, $first_arg, $sec_arg);
        echo "        <arg2 type=\"string\">{$instruction[2]}</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^(int|bool|string)$/', ($instruction[2])))
    {
      $sec_arg = "type";
      paramsValidateTwo($instruction, $first_arg, $sec_arg);
      echo "        <arg2 type=\"type\">{$instruction[2]}</arg2>\n";
    }
    else if ((preg_match('/^(GF|LF|TF)@.*$/', strtoupper($instruction[2]))))
    {
      if (preg_match('/^(GF|LF|TF)@([[:alpha:]]|(_|-|\$|&|\?|!|%|\*))([[:alnum:]]|(_|-|\$|&|\?|!|%|\*))*/', ($instruction[2])))
      {
        $sec_arg = "var";
        paramsValidateTwo($instruction, $first_arg, $sec_arg);
        $instruction[2] = preg_replace('/&/', "&amp;", $instruction[2]);
        $instruction[2] = preg_replace('/</', "&lt;", $instruction[2]);
        $instruction[2] = preg_replace('/>/', "&gt;", $instruction[2]);
        echo "        <arg2 type=\"var\">{$instruction[2]}</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil@.*$/', strtolower($instruction[2])))
    {
      if (preg_match('/^nil@nil$/', ($instruction[2])))
      {
        $sec_arg = "nil";
        paramsValidateTwo($instruction, $first_arg, $sec_arg);
        $instruction[2] = substr(($instruction[2]),4);
        echo "        <arg2 type=\"nil\">{$instruction[2]}</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil$/', strtolower($instruction[2])))
    {
      Err();
    }
    else if (preg_match('/[[:alnum:]]@.*$/', ($instruction[2])))
    {
      Err();
    }
    else if (preg_match('/^([[:alpha:]]|(_|-|\$|&|%|\*))((_|-|\$|&|%|\*)|[[:alnum:]])*/', ($instruction[2])))
    {
      $sec_arg = "label";
      paramsValidateTwo($instruction, $first_arg, $sec_arg);
      echo "        <arg2 type=\"label\">{$instruction[2]}</arg2>\n";
    }
    else
    {
      Err();
    }

  }

  else if (count($instruction) == 4)
  { // INSTRUKCE S TREMI ARGUMENTY
    //////////////////////////////////// prvni argument instrukce /////////////////////////////////////////////////////
    if (preg_match('/^int@.*$/', strtolower($instruction[1])))
    {
      if ((preg_match('/^int@[-+]?\d+$/', ($instruction[1]))))
      {
        $first_arg = "int";
        $instruction[1] = ltrim(($instruction[1]),"int@");
        echo "        <arg1 type=\"int\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^bool@.*$/', strtolower($instruction[1])))
    {
      if (preg_match('/^bool@true$/', ($instruction[1])))
      {
        $first_arg = "bool_t";
        echo "        <arg1 type=\"bool\">true</arg1>\n";
      }
      else if (preg_match('/^bool@false$/', ($instruction[1])))
      {
        $first_arg = "bool_f";
        echo "        <arg1 type=\"bool\">false</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^string@.*$/', strtolower($instruction[1])))
    {
      if (preg_match('/^^string@(([a-zA-Z\x{0021}\x{0022}\x{0024}-\x{005B}\x{005D}-\x{FFFF}])|(\\\\[0-9][0-9][0-9]))*$/', ($instruction[1])))
      {
        $first_arg = "string";
        $instruction[1] = substr(($instruction[1]),7);
        $instruction[1] = preg_replace('/&/', "&amp;", $instruction[1]);
        $instruction[1] = preg_replace('/</', "&lt;", $instruction[1]);
        $instruction[1] = preg_replace('/>/', "&gt;", $instruction[1]);
        echo "        <arg1 type=\"string\">{$instruction[1]}</arg1>\n";
      }
      else if (preg_match('/^string@[^\u0000-\u007F]+/', ($instruction[1])))
      {
        $first_arg = "string";
        echo "        <arg1 type=\"string\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^(int|bool|string)$/', ($instruction[1])))
    {
      $first_arg = "type";
      echo "        <arg1 type=\"type\">{$instruction[1]}</arg1>\n";
    }
    else if ((preg_match('/^(GF|LF|TF)@.*$/', strtoupper($instruction[1]))))
    {
      if (preg_match('/^(GF|LF|TF)@([[:alpha:]]|(_|-|\$|&|\?|!|%|\*))([[:alnum:]]|(_|-|\$|&|\?|!|%|\*))*/', ($instruction[1])))
      {
        $first_arg = "var";
        $instruction[1] = preg_replace('/&/', "&amp;", $instruction[1]);
        $instruction[1] = preg_replace('/</', "&lt;", $instruction[1]);
        $instruction[1] = preg_replace('/>/', "&gt;", $instruction[1]);
        echo "        <arg1 type=\"var\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil@.*$/', strtolower($instruction[1])))
    {
      if (preg_match('/^nil@nil$/', ($instruction[1])))
      {
        $first_arg = "nil";
        $instruction[1] = substr(($instruction[1]),4);
        echo "        <arg1 type=\"nil\">{$instruction[1]}</arg1>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil$/', strtolower($instruction[1])))
    {
      Err();
    }
    else if (preg_match('/[[:alnum:]]@.*$/', ($instruction[1])))
    {
      Err();
    }
    else if (preg_match('/^([[:alpha:]]|(_|-|\$|&|%|\*))((_|-|\$|&|%|\*)|[[:alnum:]])*/', ($instruction[1])))
    {
      $first_arg = "label";
      echo "        <arg1 type=\"label\">{$instruction[1]}</arg1>\n";
    }
    else
    {
      Err();
    }
  //////////////////////////////////// druhy argument instrukce /////////////////////////////////////////////////////
    if (preg_match('/^int@.*$/', strtolower($instruction[2])))
    {
      if ((preg_match('/^int@[-+]?\d+$/', ($instruction[2]))))
      {
        $sec_arg = "int";
        $instruction[2] = ltrim(($instruction[2]),"int@");
        echo "        <arg2 type=\"int\">{$instruction[2]}</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^bool@.*$/', strtolower($instruction[2])))
    {
      if (preg_match('/^bool@true$/', ($instruction[2])))
      {
        $sec_arg = "bool_t";
        echo "        <arg2 type=\"bool\">true</arg2>\n";
      }
      else if (preg_match('/^bool@false$/', ($instruction[2])))
      {
        $sec_arg = "bool_f";
        echo "        <arg2 type=\"bool\">false</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^string@.*$/', strtolower($instruction[2])))
    {
      if (preg_match('/^^string@(([a-zA-Z\x{0021}\x{0022}\x{0024}-\x{005B}\x{005D}-\x{FFFF}])|(\\\\[0-9][0-9][0-9]))*$/', ($instruction[2])))
      {
        $sec_arg = "string";
        $instruction[2] = substr(($instruction[2]),7);
        $instruction[2] = preg_replace('/&/', "&amp;", $instruction[2]);
        $instruction[2] = preg_replace('/</', "&lt;", $instruction[2]);
        $instruction[2] = preg_replace('/>/', "&gt;", $instruction[2]);
        echo "        <arg2 type=\"string\">{$instruction[2]}</arg2>\n";
      }
      else if (preg_match('/^string@[^\u0000-\u007F]+/', ($instruction[2])))
      {
        $sec_arg = "string";
        echo "        <arg2 type=\"string\">{$instruction[2]}</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^(int|bool|string)$/', ($instruction[2])))
    {
      $sec_arg = "type";
      echo "        <arg2 type=\"type\">{$instruction[2]}</arg2>\n";
    }
    else if ((preg_match('/^(GF|LF|TF)@.*$/', strtoupper($instruction[2]))))
    {
      if (preg_match('/^(GF|LF|TF)@([[:alpha:]]|(_|-|\$|&|\?|!|%|\*))([[:alnum:]]|(_|-|\$|&|\?|!|%|\*))*/', ($instruction[2])))
      {
        $sec_arg = "var";
        $instruction[2] = preg_replace('/&/', "&amp;", $instruction[2]);
        $instruction[2] = preg_replace('/</', "&lt;", $instruction[2]);
        $instruction[2] = preg_replace('/>/', "&gt;", $instruction[2]);
        echo "        <arg2 type=\"var\">{$instruction[2]}</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil@.*$/', strtolower($instruction[2])))
    {
      if (preg_match('/^nil@nil$/', ($instruction[2])))
      {
        $sec_arg = "nil";
        $instruction[2] = substr(($instruction[2]),4);
        echo "        <arg2 type=\"nil\">{$instruction[2]}</arg2>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil$/', strtolower($instruction[2])))
    {
      Err();
    }
    else if (preg_match('/[[:alnum:]]@.*$/', ($instruction[2])))
    {
      Err();
    }
    else if (preg_match('/^([[:alpha:]]|(_|-|\$|&|%|\*))((_|-|\$|&|%|\*)|[[:alnum:]])*/', ($instruction[2])))
    {
      $sec_arg = "label";
      echo "        <arg2 type=\"label\">{$instruction[2]}</arg2>\n";
    }
    else
    {
      Err();
    }
    //////////////////////////////////// treti argument instrukce /////////////////////////////////////////////////////
    if (preg_match('/^int@.*$/', strtolower($instruction[3])))
    {
      if ((preg_match('/^int@[-+]?\d+$/', ($instruction[3]))))
      {
        $th_arg = "int";
        paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg);
        $instruction[3] = ltrim(($instruction[3]),"int@");
        echo "        <arg3 type=\"int\">{$instruction[3]}</arg3>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^bool@.*$/', strtolower($instruction[3])))
    {
      if (preg_match('/^bool@true$/', ($instruction[3])))
      {
        $th_arg = "bool_t";
        paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg);
        echo "        <arg3 type=\"bool\">true</arg3>\n";
      }
      else if (preg_match('/^bool@false$/', ($instruction[3])))
      {
        $th_arg = "bool_f";
        paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg);
        echo "        <arg3 type=\"bool\">false</arg3>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^string@.*$/', strtolower($instruction[3])))
    {
      if (preg_match('/^^string@(([a-zA-Z\x{0021}\x{0022}\x{0024}-\x{005B}\x{005D}-\x{FFFF}])|(\\\\[0-9][0-9][0-9]))*$/', ($instruction[3])))
      {
        $th_arg = "string";
        paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg);
        $instruction[3] = substr(($instruction[3]),7);
        $instruction[3] = preg_replace('/&/', "&amp;", $instruction[3]);
        $instruction[3] = preg_replace('/</', "&lt;", $instruction[3]);
        $instruction[3] = preg_replace('/>/', "&gt;", $instruction[3]);
        echo "        <arg3 type=\"string\">{$instruction[3]}</arg3>\n";
      }
      else if (preg_match('/^string@[^\u0000-\u007F]+/', ($instruction[3])))
      {
        $th_arg = "string";
        paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg);
        echo "        <arg3 type=\"string\">{$instruction[3]}</arg3>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^(int|bool|string)$/', ($instruction[3])))
    {
      $th_arg = "type";
      paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg);
      echo "        <arg3 type=\"type\">{$instruction[3]}</arg3>\n";
    }
    else if ((preg_match('/^(GF|LF|TF)@.*$/', strtoupper($instruction[3]))))
    {
      if (preg_match('/^(GF|LF|TF)@([[:alpha:]]|(_|-|\$|&|\?|!|%|\*))([[:alnum:]]|(_|-|\$|&|\?|!|%|\*))*/', ($instruction[3])))
      {
        $th_arg = "var";
        paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg);
        $instruction[3] = preg_replace('/&/', "&amp;", $instruction[3]);
        $instruction[3] = preg_replace('/</', "&lt;", $instruction[3]);
        $instruction[3] = preg_replace('/>/', "&gt;", $instruction[3]);
        echo "        <arg3 type=\"var\">{$instruction[3]}</arg3>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil@.*$/', strtolower($instruction[3])))
    {
      if (preg_match('/^nil@nil$/', ($instruction[3])))
      {
        $th_arg = "nil";
        paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg);
        $instruction[3] = substr(($instruction[3]),4);
        echo "        <arg3 type=\"nil\">{$instruction[3]}</arg3>\n";
      }
      else
      {
        Err();
      }
    }
    else if (preg_match('/^nil$/', strtolower($instruction[3])))
    {
      Err();
    }
    else if (preg_match('/[[:alnum:]]@.*$/', ($instruction[3])))
    {
      Err();
    }
    else if (preg_match('/^([[:alpha:]]|(_|-|\$|&|%|\*))((_|-|\$|&|%|\*)|[[:alnum:]])*/', ($instruction[3])))
    {
      $th_arg = "label";
      paramsValidateThree($instruction, $first_arg, $sec_arg, $th_arg);
      echo "        <arg3 type=\"label\">{$instruction[3]}</arg3>\n";
    }
    else
    {
      Err();
    }

  }

}

/////////////////////////////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////
// vypis napovedy -
if (($argc == 2) && $argv[2] = '--help' )
{
  echo ("Napoveda - Program parse.php nacita z STDIN kod v jazyce IPPcode19\nInterpretuje ho ve formatu xml na STDOUT\n");
  exit(0);
}
// spatny pocet parametru
if ($argc > 2)
{
  fprintf (STDERR, "Chyba - Program spoustite se spatnym poctem parametru!\n");
  exit(22);
}

Opening();
echo "</program>\n";

?>
