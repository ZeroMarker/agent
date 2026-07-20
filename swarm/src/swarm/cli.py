import argparse
import os

from dotenv import load_dotenv

from .graph import run


def main() -> None:
    load_dotenv()
    parser = argparse.ArgumentParser(description="Run the LangGraph DeepSeek swarm")
    parser.add_argument("task", help="Task for the swarm")
    parser.add_argument("--max-steps", type=int, default=int(os.getenv("SWARM_MAX_STEPS", "8")))
    parser.add_argument("--trace", action="store_true")
    args = parser.parse_args()
    result = run(args.task, max_steps=args.max_steps)
    print(result["final"])
    if args.trace:
        print("\nTrace: " + " -> ".join(result["trace"]))


if __name__ == "__main__":
    main()
