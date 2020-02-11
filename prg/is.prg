#include "box.ch"

#include "functions.ch"

#define BLINKING_PART '\*?'
#define INTENSITY_PART '\+?'
#define COLOR_PART '((RB)|(GR)|(BG)|([UIXWNRGB]))'

FUNCTION is_data_type(cType)

    IF PCount() != 1
        throw(ARGUMENTS_NUMBER_EXCEPTION)
    ELSEIF ValType(cType) != 'C' .OR. Len(cType) != 1
        RETURN .F.
    ENDIF

RETURN cType $ 'A;O;H;L;N;D;C;U;B;M;P;T;S'

FUNCTION is_number_string(cVariable, lAllowSpaces)

    LOCAL lWasDecimalPoint := .F.
    LOCAL lWasMinusSign := .F.
    LOCAL lWasDigit := .F.
    LOCAL cDigit

    IF PCount() != 2 .AND. PCount() != 1 
        throw(ARGUMENTS_NUMBER_EXCEPTION)
    ELSEIF PCount() == 2 .AND. ValType(lAllowSpaces) != 'L'
        throw(ARGUMENT_TYPE_EXCEPTION)
    ENDIF

    IF hb_PIsByRef(1)
        throw(PASS_BY_REFERENCE_EXCEPTION)
    ENDIF

    IF ValType(cVariable) != 'C'
        RETURN .F.
    ENDIF

    IF PCount() == 2 .AND. lAllowSpaces
        cVariable := AllTrim(cVariable)
    ENDIF

    FOR EACH cDigit IN cVariable
        IF IsDigit(cDigit)
            lWasDigit := .T.
        ELSE
            IF lWasDecimalPoint .AND. cDigit == '.'
                RETURN .F.
            ELSEIF lWasMinusSign .AND. cDigit == '-'
                RETURN .F.
            ELSEIF !lWasDecimalPoint .AND. cDigit == '.'
                lWasDecimalPoint := .T.
            ELSEIF !lWasMinusSign .AND. cDigit == '-'
                IF lWasDecimalPoint .OR. lWasDigit
                    RETURN .F.    
                ELSE
                    lWasMinusSign := .T.
                ENDIF
            ELSE
                RETURN .F.
            ENDIF
        ENDIF
    NEXT

RETURN .T.

FUNCTION is_date_string(cVariable, lAllowSpaces)

    IF PCount() == 2
        assert_type(lAllowSpaces, 'L')
    ENDIF

    IF ValType(cVariable) != 'C'
        RETURN .F.
    ENDIF

    IF hb_PIsByRef(1)
        throw(PASS_BY_REFERENCE_EXCEPTION)
    ENDIF

    IF PCount() == 2 .AND. lAllowSpaces
        cVariable := AllTrim(cVariable)
    ENDIF

    IF !is_number_string(cVariable)
        RETURN .F.
    ENDIF

    IF Len(cVariable) != 8
        RETURN .F.
    ENDIF

RETURN .T.

FUNCTION is_logical_string(cVariable, lAllowSpaces)

    IF PCount() == 2
        assert_type(lAllowSpaces, 'L')
    ENDIF

    IF ValType(cVariable) != 'C'
        RETURN .F.
    ENDIF

    IF hb_PIsByRef(1)
        throw(PASS_BY_REFERENCE_EXCEPTION)
    ENDIF

    IF PCount() == 2 .AND. lAllowSpaces
        cVariable := AllTrim(cVariable)
    ENDIF

    IF Len(cVariable) == 3 .AND. cVariable == '.T.' .OR. cVariable == '.F.'
        RETURN .T.
    ELSEIF Len(cVariable) == 1 .AND. cVariable $ 'T;F;Y;N'
        RETURN .T.
    ENDIF

RETURN .F.

FUNCTION is_color(cColorString, lAllowSpaces, cPattern)

    LOCAL acColors
    LOCAL nSlash
    LOCAL cColor
    LOCAL pRegEx

    IF PCount() != 1 .AND. PCount() != 2 .AND. PCount() != 3
        throw(ARGUMENTS_NUMBER_EXCEPTION)
    ENDIF

    IF PCount() > 1
        assert_type(lAllowSpaces, 'L')
    ENDIF

    IF PCount() > 2
        assert_type(cPattern, 'C')
        assert_length(cPattern, 3)
    ENDIF

    IF ValType(cColorString) != 'C'
        RETURN .F.
    ENDIF

    IF hb_PIsByRef(1)
        throw(PASS_BY_REFERENCE_EXCEPTION)
    ENDIF

    IF PCount() >= 2 .AND. lAllowSpaces
        cColorString := AllTrim(cColorString)
    ENDIF

    IF PCount() == 3
        pRegEx := create_color_regexp(cPattern)
    ELSE
        pRegEx := create_color_regexp(REGEXP_COLOR_PART + REGEXP_INTENSITY_PART + REGEXP_BLINKING_PART)
    ENDIF

    acColors := hb_ATokens(cColorString, ',')

    FOR EACH cColor IN acColors
        IF Empty(cColor)
            LOOP
        ENDIF

        nSlash := At('/', cColor)

        IF nSlash == 0
            RETURN .F.
        ENDIF

        IF !hb_RegExLike(pRegEx, Left(cColor, nSlash - 1)) .OR. !hb_RegExLike(pRegEx, SubStr(cColor, nSlash + 1))
            RETURN .F.
        ENDIF
    NEXT

RETURN .T.

STATIC FUNCTION create_color_regexp(cPattern)
    
    LOCAL nLength := Len(cPattern)
    LOCAL cRegEx := ''
    LOCAL cLetter
    LOCAL i

    FOR i := 1 TO nLength
        cLetter := SubStr(cPattern, i, 1)
        DO CASE
            CASE cLetter == REGEXP_COLOR_PART
                cRegEx += COLOR_PART
            CASE cLetter == REGEXP_BLINKING_PART
                cRegEx += BLINKING_PART
            CASE cLetter == REGEXP_INTENSITY_PART
                cRegEx += INTENSITY_PART
            OTHERWISE
                throw(ARGUMENT_VALUE_EXCEPTION)
        ENDCASE
    NEXT

RETURN hb_RegExComp(cRegEx)

FUNCTION is_box(cBoxString)

    IF PCount() != 1
        throw(ARGUMENTS_NUMBER_EXCEPTION)
    ENDIF

RETURN ValType(cBoxString) == 'C' //.AND. Len(cBoxString) == STD_BOX_STRING_LENGTH TODO Doesn't work with UTF8 and when Len(cBoxString) == 9

FUNCTION is_style(cStyleString)

    IF PCount() != 1
        throw(ARGUMENTS_NUMBER_EXCEPTION)
    ENDIF

RETURN ValType(cStyleString) == 'C' .AND. Len(cStyleString) == STD_STYLE_STRING_LENGTH

FUNCTION is_picture(cPicture)

    IF PCount() != 1
        throw(ARGUMENTS_NUMBER_EXCEPTION)
    ENDIF

RETURN ValType(cPicture) == 'C' .AND. is_function_picture(get_function_from_picture(cPicture)) .AND. is_template_picture(get_template_from_picture(cPicture))

FUNCTION is_function_picture(cFunction)

    LOCAL lScrolling := .F.
    LOCAL lCheckNextIsDigit := .F.
    LOCAL cCharacter

    IF PCount() != 1
        throw(ARGUMENTS_NUMBER_EXCEPTION)
    ENDIF

    IF ValType(cFunction) != 'C'
        RETURN .F.
    ENDIF

    FOR EACH cCharacter IN cFunction

        IF lCheckNextIsDigit
            lCheckNextIsDigit := .F.
            IF !isDigit(cCharacter)
                RETURN .F.
            ENDIF
            CONTINUE
        ELSEIF cCharacter == 'S'
            lScrolling := .T.
            lCheckNextIsDigit := .T.
        ELSEIF lScrolling .AND. isDigit(cCharacter)
            CONTINUE
        ELSEIF cCharacter $ 'A;B;C;D;E;K;R;X;Z(;);!;@'
            lScrolling := .F.
            CONTINUE
        ELSE
            RETURN .F.
        ENDIF
    NEXT

RETURN .T.

FUNCTION is_template_picture(cTemplate)

    LOCAL cCharacter

    IF PCount() != 1
        throw(ARGUMENTS_NUMBER_EXCEPTION)
    ENDIF

    IF ValType(cTemplate) != 'C'
        RETURN .F.
    ENDIF

    FOR EACH cCharacter IN cTemplate
        IF cCharacter $ 'A;N;X;9;#;L;Y;!;$;*;.;,'
            CONTINUE
        ELSE
            RETURN .F.
        ENDIF
    NEXT

RETURN .T.
