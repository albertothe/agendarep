// backend/src/types.d.ts

import { JwtPayload } from "./middlewares/autenticar"

declare global {
    namespace Express {
        interface Request {
            user?: JwtPayload
        }
    }
}

export { }
