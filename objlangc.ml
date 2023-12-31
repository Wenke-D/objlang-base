open Format
open Format_error

let () = Printexc.record_backtrace true

let source_file_extension = ".obj"

let () =
  try
    let file = Sys.argv.(1) in
    let c = open_in file in
    let lb = Lexing.from_channel c in
    let prog =
      try Objlangparser.program Objlanglexer.token lb
      with Objlangparser.Error ->
        let pos = lb.lex_curr_p in
        let (p : Error_syntax.position) = Error_syntax.make_position pos in
        raise (Error_syntax.SyntaxError p)
    in
    close_in c ;
    (* typing *)
    let tprog = Objlangtyper.type_program prog in
    (* to imp *)
    let imp = Obj2imp.translate_program tprog in
    (* output .imp *)
    let imp_output_file =
      Filename.chop_suffix file source_file_extension ^ ".imp"
    in
    let imp_out = open_out imp_output_file in
    let imp_outf = formatter_of_out_channel imp_out in
    Imppp.print_program imp_outf imp ;
    pp_print_flush imp_outf () ;
    close_out imp_out ;
    (* to mips *)
    let asm = Imp2mips.translate_program imp in
    (* output .asm *)
    let output_file =
      Filename.chop_suffix file source_file_extension ^ ".asm"
    in
    let out = open_out output_file in
    let outf = formatter_of_out_channel out in
    Mips.print_program outf asm ;
    pp_print_flush outf () ;
    close_out out ;
    exit 0
  with
  | Error_syntax.SyntaxError p ->
      exit_with_error (Error_syntax.format_syntax_error p)
  | Error_type.UndefinedError data ->
      exit_with_error (Error_type.format_undefined_error data)
  | Error_type.UnexpectedTypeError data ->
      exit_with_error (Error_type.format_unexpected_type_error data)
  | Error_type.ArgumentLengthError data ->
      exit_with_error (Error_type.format_argument_length_error data)
