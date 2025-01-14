/**
  Parameters:
    - event_data: The 'data' field of the IndexerTendermintEvent (https://github.com/dydxprotocol/v4-proto/blob/8d35c86/dydxprotocol/indexer/indexer_manager/event.proto#L25)
        converted to JSON format. Conversion to JSON is expected to be done by JSON.stringify.
  Returns: JSON object containing fields:
    - market: The updated market in market-model format (https://github.com/dydxprotocol/indexer/blob/cc70982/packages/postgres/src/models/market-model.ts).
*/
CREATE OR REPLACE FUNCTION dydx_market_modify_handler(event_data jsonb) RETURNS jsonb AS $$
DECLARE
    market_record_id integer;
    market_record markets%ROWTYPE;
BEGIN
    market_record_id = (event_data->'marketId')::integer;
    SELECT * INTO market_record FROM markets WHERE "id" = market_record_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION E'Market in MarketModify doesn\'t exist. Id: %', market_record_id;
    END IF;

    market_record."pair" = event_data->'marketModify'->'base'->>'pair';
    market_record."minPriceChangePpm" = (event_data->'marketModify'->'base'->'minPriceChangePpm')::integer;

    UPDATE markets
    SET
        "pair" = market_record."pair",
        "minPriceChangePpm" = market_record."minPriceChangePpm"
    WHERE id = market_record."id";

    RETURN jsonb_build_object(
        'market',
        dydx_to_jsonb(market_record)
    );
END;
$$ LANGUAGE plpgsql;